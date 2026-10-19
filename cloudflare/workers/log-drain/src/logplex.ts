// Pure helpers for the Heroku HTTPS log drain: parse logplex frames into
// `heroku logs`-style lines, name R2 objects, and filter lines by time.

const decoder = new TextDecoder();

// A logplex body is a run of octet-counted syslog frames: "<len> <msg><len> <msg>…"
// where <len> counts bytes, not characters. Each <msg> is RFC 5424 as Heroku
// sends it: "<190>1 2026-10-19T20:01:51.596325+00:00 host app web.1 - message".
// Returns lines in the `heroku logs` format the app's parsers already read:
// "2026-10-19T20:01:51.596325+00:00 app[web.1]: message".
export function parseLogplex(body: Uint8Array): string[] {
  const lines: string[] = [];
  let i = 0;
  while (i < body.length) {
    let len = 0;
    let digits = 0;
    while (i < body.length && body[i] >= 0x30 && body[i] <= 0x39) {
      len = len * 10 + (body[i] - 0x30);
      i++;
      digits++;
    }
    // Not a frame header: stop rather than misread the rest of the body.
    if (digits === 0 || body[i] !== 0x20) break;
    i++;
    const frame = decoder.decode(body.subarray(i, i + len));
    i += len;
    const line = syslogToLine(frame);
    if (line) lines.push(line);
  }
  return lines;
}

export function syslogToLine(frame: string): string | null {
  const msg = frame.replace(/\r?\n$/, "");
  const match = msg.match(/^<\d+>\d+ (\S+) \S+ (\S+) (\S+) \S+ ?([\s\S]*)$/);
  if (!match) return null;
  const [, timestamp, source, dyno, text] = match;
  return `${timestamp} ${source}[${dyno}]: ${text}`;
}

// Milliseconds since the epoch for a line's leading timestamp, or null.
export function lineTime(line: string): number | null {
  const ms = Date.parse(line.slice(0, line.indexOf(" ")));
  return Number.isNaN(ms) ? null : ms;
}

// Compact sortable UTC stamp: 20261019T202151596Z.
export function stamp(ms: number): string {
  return new Date(ms).toISOString().replace(/[-:.]/g, "");
}

export function parseStamp(s: string): number {
  const m = s.match(/^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(\d{3})Z$/);
  if (!m) return NaN;
  const [, y, mo, d, h, mi, sec, msec] = m.map(Number);
  return Date.UTC(y, mo - 1, d, h, mi, sec, msec);
}

// "motzi/2026/10/19/20/"
export function hourPrefix(app: string, ms: number): string {
  const iso = new Date(ms).toISOString();
  return `${app}/${iso.slice(0, 4)}/${iso.slice(5, 7)}/${iso.slice(8, 10)}/${iso.slice(11, 13)}/`;
}

// One object per flush, filed under the hour of its earliest line. The key
// carries the batch's first and last line times so reads can skip objects
// without fetching them, and keys sort in time order within an hour.
export function objectKey(
  app: string,
  firstMs: number,
  lastMs: number,
  nonce: string
): string {
  return `${hourPrefix(app, firstMs)}${stamp(firstMs)}-${stamp(lastMs)}-${nonce}.log`;
}

export function keyRange(key: string): { first: number; last: number } | null {
  const m = key.match(/\/(\d{8}T\d{9}Z)-(\d{8}T\d{9}Z)-[^/]+\.log$/);
  if (!m) return null;
  return { first: parseStamp(m[1]), last: parseStamp(m[2]) };
}

// The earliest and latest line times in a batch (dynos interleave, so the
// lines aren't strictly ordered). Lines without a timestamp use `fallback`.
export function batchRange(
  lines: string[],
  fallback: number
): { first: number; last: number } {
  let first = Infinity;
  let last = -Infinity;
  for (const line of lines) {
    const t = lineTime(line) ?? fallback;
    if (t < first) first = t;
    if (t > last) last = t;
  }
  if (first === Infinity) return { first: fallback, last: fallback };
  return { first, last };
}

// "30m", "2h", "1d" ago, or an ISO time.
export function parseSince(value: string, now: number): number | null {
  const rel = value.match(/^(\d+)([mhd])$/);
  if (rel) {
    const unit = { m: 60_000, h: 3_600_000, d: 86_400_000 }[
      rel[2] as "m" | "h" | "d"
    ];
    return now - Number(rel[1]) * unit;
  }
  const ms = Date.parse(value);
  return Number.isNaN(ms) ? null : ms;
}

export function filterLines(
  lines: string[],
  since: number,
  until: number,
  query: string | null
): string[] {
  const q = query?.toLowerCase();
  return lines.filter((line) => {
    const t = lineTime(line);
    if (t !== null && (t < since || t > until)) return false;
    return !q || line.toLowerCase().includes(q);
  });
}
