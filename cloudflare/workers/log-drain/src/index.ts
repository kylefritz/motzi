import { DurableObject } from "cloudflare:workers";
import {
  batchRange,
  filterLines,
  hourPrefix,
  keyRange,
  lineTime,
  objectKey,
  parseLogplex,
  parseSince,
} from "./logplex";

interface Env {
  LOGS: R2Bucket;
  LOG_BUFFER: DurableObjectNamespace<LogBuffer>;
  APPS: string; // comma-separated app names allowed in the path
  DRAIN_TOKEN: string;
  READ_TOKEN: string;
}

// Buffer lines for a minute (or 1MB) per R2 object. One object per drain POST
// would use most of R2's free write quota.
const FLUSH_MS = 60_000;
const FLUSH_BYTES = 1_000_000;
// If R2 is down, keep at most this much and drop the oldest lines.
const MAX_BUFFER_BYTES = 50_000_000;
// Free-plan Workers get 50 subrequests per request; R2 list/get and the
// Durable Object call all count. Leave headroom.
const READ_BUDGET = 40;
// Objects are filed under the hour of their earliest line; start listing a
// little before `since` so a batch that straddles it isn't missed.
const LOOKBACK_MS = 10 * 60_000;
const HOUR_MS = 3_600_000;

// One buffer per app, flushed to R2 on an alarm. Each drain POST is one row
// in the object's SQLite storage, so a restart (deploy, eviction, runtime
// update) doesn't lose lines that haven't been flushed yet.
export class LogBuffer extends DurableObject<Env> {
  private sql: SqlStorage;
  private bytes = 0;

  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    this.sql = ctx.storage.sql;
    this.sql.exec(
      "CREATE TABLE IF NOT EXISTS buffer (id INTEGER PRIMARY KEY AUTOINCREMENT, app TEXT NOT NULL, body TEXT NOT NULL)"
    );
    this.bytes = this.sql
      .exec<{ bytes: number }>(
        "SELECT COALESCE(SUM(LENGTH(body)), 0) AS bytes FROM buffer"
      )
      .one().bytes;
  }

  async append(app: string, lines: string[]): Promise<void> {
    const body = lines.join("\n");
    this.sql.exec("INSERT INTO buffer (app, body) VALUES (?, ?)", app, body);
    this.bytes += body.length + 1;
    this.trim();

    if (this.bytes >= FLUSH_BYTES) {
      await this.flush();
    } else if ((await this.ctx.storage.getAlarm()) === null) {
      await this.ctx.storage.setAlarm(Date.now() + FLUSH_MS);
    }
  }

  async alarm(): Promise<void> {
    await this.flush();
  }

  // Lines not yet in R2, so reads see the last minute too.
  pending(): string[] {
    return this.rows().flatMap((row) => row.body.split("\n"));
  }

  private rows(): { id: number; app: string; body: string }[] {
    return this.sql
      .exec<{ id: number; app: string; body: string }>(
        "SELECT id, app, body FROM buffer ORDER BY id"
      )
      .toArray();
  }

  private async flush(): Promise<void> {
    const rows = this.rows();
    if (rows.length === 0) return;

    const batch = rows.flatMap((row) => row.body.split("\n"));
    const { first, last } = batchRange(batch, Date.now());
    const key = objectKey(
      rows[0].app,
      first,
      last,
      crypto.randomUUID().slice(0, 8)
    );
    try {
      await this.env.LOGS.put(key, batch.join("\n") + "\n", {
        httpMetadata: { contentType: "text/plain; charset=utf-8" },
      });
    } catch (err) {
      // Keep the rows and try again on the next alarm.
      console.error("log-drain: R2 put failed, keeping the batch", err);
      if ((await this.ctx.storage.getAlarm()) === null) {
        await this.ctx.storage.setAlarm(Date.now() + FLUSH_MS);
      }
      return;
    }
    this.sql.exec("DELETE FROM buffer WHERE id <= ?", rows[rows.length - 1].id);
    this.bytes = 0;
  }

  // If R2 stays down, keep at most MAX_BUFFER_BYTES and drop the oldest rows.
  private trim(): void {
    while (this.bytes > MAX_BUFFER_BYTES) {
      const oldest = this.sql
        .exec<{ id: number; len: number }>(
          "SELECT id, LENGTH(body) AS len FROM buffer ORDER BY id LIMIT 1"
        )
        .toArray()[0];
      if (!oldest) break;
      this.sql.exec("DELETE FROM buffer WHERE id = ?", oldest.id);
      this.bytes -= oldest.len + 1;
    }
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const [, app, action, ...rest] = url.pathname.split("/");
    const apps = env.APPS.split(",").map((a) => a.trim());
    if (!app || !apps.includes(app) || rest.length > 0) {
      return new Response("Not found\n", { status: 404 });
    }

    if (action === "drain" && request.method === "POST") {
      // Heroku sends the drain URL's userinfo as basic auth.
      if (!tokenMatches(basicPassword(request), env.DRAIN_TOKEN)) {
        return new Response("Unauthorized\n", { status: 401 });
      }
      const lines = parseLogplex(new Uint8Array(await request.arrayBuffer()));
      if (lines.length > 0) await buffer(env, app).append(app, lines);
      return new Response(null, { status: 204 });
    }

    if (action === "logs" && request.method === "GET") {
      if (!tokenMatches(bearerToken(request), env.READ_TOKEN)) {
        return new Response("Unauthorized\n", { status: 401 });
      }
      return readLogs(env, app, url);
    }

    return new Response("Not found\n", { status: 404 });
  },
};

// GET /<app>/logs?since=30m&until=<iso>&q=<text>&cursor=<from X-Next-Cursor>
// Returns `heroku logs`-style text, oldest first. When the window needs more
// R2 reads than one request allows, the response has an X-Next-Cursor header;
// repeat the same query with cursor=<value> to continue.
async function readLogs(env: Env, app: string, url: URL): Promise<Response> {
  const now = Date.now();
  const since = parseSince(url.searchParams.get("since") ?? "30m", now);
  const untilParam = url.searchParams.get("until");
  const until = untilParam ? parseSince(untilParam, now) : now;
  if (since === null || until === null || since > until) {
    return new Response("Bad since/until\n", { status: 400 });
  }
  const query = url.searchParams.get("q");
  const cursor = url.searchParams.get("cursor");
  if (cursor && !cursor.startsWith(`${app}/`)) {
    return new Response("Bad cursor\n", { status: 400 });
  }

  const out: string[] = [];
  let budget = READ_BUDGET;
  let resumeAfter = cursor ?? undefined;
  let next: string | null = null;

  const startHour = cursor
    ? cursorHour(cursor)
    : Math.floor((since - LOOKBACK_MS) / HOUR_MS) * HOUR_MS;

  scan: for (let hour = startHour; hour <= until; hour += HOUR_MS) {
    const prefix = hourPrefix(app, hour);
    const startAfter =
      resumeAfter && resumeAfter.startsWith(prefix) ? resumeAfter : undefined;
    let listCursor: string | undefined;
    do {
      if (budget <= 1) {
        next = resumeAfter?.startsWith(prefix) ? resumeAfter : prefix;
        break scan;
      }
      const listing = await env.LOGS.list({
        prefix,
        startAfter: listCursor ? undefined : startAfter,
        cursor: listCursor,
      });
      budget--;
      for (const object of listing.objects) {
        const range = keyRange(object.key);
        if (!range || range.last < since || range.first > until) continue;
        if (budget <= 1) {
          next = resumeAfter?.startsWith(prefix) ? resumeAfter : prefix;
          break scan;
        }
        const body = await env.LOGS.get(object.key);
        budget--;
        if (body)
          out.push(
            ...filterLines(splitLines(await body.text()), since, until, query)
          );
        resumeAfter = object.key;
      }
      listCursor = listing.truncated ? listing.cursor : undefined;
    } while (listCursor);
  }

  if (next === null && until >= now - FLUSH_MS * 2) {
    out.push(
      ...filterLines(await buffer(env, app).pending(), since, until, query)
    );
  }

  // Dynos interleave within a batch, so order by time. Continuation lines of
  // a multi-line message have no timestamp; they keep the one before them.
  let prev = 0;
  const timed = out.map((line, i) => {
    prev = lineTime(line) ?? prev;
    return { line, i, t: prev };
  });
  timed.sort((a, b) => a.t - b.t || a.i - b.i);

  const headers: Record<string, string> = {
    "Content-Type": "text/plain; charset=utf-8",
    "Cache-Control": "no-store",
  };
  if (next) headers["X-Next-Cursor"] = next;
  const text = timed.map((x) => x.line).join("\n");
  return new Response(text ? text + "\n" : "", { headers });
}

function buffer(env: Env, app: string): DurableObjectStub<LogBuffer> {
  return env.LOG_BUFFER.get(env.LOG_BUFFER.idFromName(app));
}

// "motzi/2026/10/19/20/…" → the start of that hour.
function cursorHour(cursor: string): number {
  const [, y, m, d, h] = cursor.split("/").map(Number);
  return Date.UTC(y, m - 1, d, h);
}

function splitLines(text: string): string[] {
  return text.split("\n").filter((line) => line.length > 0);
}

function basicPassword(request: Request): string | null {
  const header = request.headers.get("Authorization") ?? "";
  if (!header.startsWith("Basic ")) return null;
  try {
    const decoded = atob(header.slice(6));
    return decoded.slice(decoded.indexOf(":") + 1);
  } catch {
    return null;
  }
}

function bearerToken(request: Request): string | null {
  const header = request.headers.get("Authorization") ?? "";
  return header.startsWith("Bearer ") ? header.slice(7) : null;
}

function tokenMatches(given: string | null, expected: string): boolean {
  if (!given || !expected) return false;
  const a = new TextEncoder().encode(given);
  const b = new TextEncoder().encode(expected);
  return a.byteLength === b.byteLength && crypto.subtle.timingSafeEqual(a, b);
}
