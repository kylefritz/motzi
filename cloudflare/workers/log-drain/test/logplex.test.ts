import { describe, expect, test } from "bun:test";
import {
  batchRange,
  filterLines,
  hourPrefix,
  keyRange,
  objectKey,
  parseLogplex,
  parseSince,
  syslogToLine,
} from "../src/logplex";

const enc = new TextEncoder();
function frames(...msgs: string[]): Uint8Array {
  return enc.encode(
    msgs.map((m) => `${enc.encode(m).byteLength} ${m}`).join("")
  );
}

describe("parseLogplex", () => {
  test("turns octet-counted syslog frames into heroku logs lines", () => {
    const body = frames(
      '<190>1 2026-10-19T20:01:51.596325+00:00 host app web.1 - I, [2026-10-19T20:01:51] INFO -- : Started GET "/menu"\n',
      '<158>1 2026-10-19T20:01:52.100000+00:00 host heroku router - at=info method=GET path="/menu" status=200'
    );
    expect(parseLogplex(body)).toEqual([
      '2026-10-19T20:01:51.596325+00:00 app[web.1]: I, [2026-10-19T20:01:51] INFO -- : Started GET "/menu"',
      '2026-10-19T20:01:52.100000+00:00 heroku[router]: at=info method=GET path="/menu" status=200',
    ]);
  });

  test("counts bytes, not characters, so multibyte text doesn't shift frames", () => {
    const body = frames(
      "<190>1 2026-10-19T20:00:00+00:00 host app web.1 - Café crème ✓",
      "<190>1 2026-10-19T20:00:01+00:00 host app worker.1 - next"
    );
    expect(parseLogplex(body)).toEqual([
      "2026-10-19T20:00:00+00:00 app[web.1]: Café crème ✓",
      "2026-10-19T20:00:01+00:00 app[worker.1]: next",
    ]);
  });

  test("keeps the memory sample format CaptureDynoMetricsJob parses", () => {
    const line = syslogToLine(
      "<45>1 2026-10-19T20:03:00+00:00 host heroku web.1 - source=web.1 dyno=heroku.1 sample#memory_total=310.5MB sample#memory_quota=512.00MB"
    );
    expect(line).toBe(
      "2026-10-19T20:03:00+00:00 heroku[web.1]: source=web.1 dyno=heroku.1 sample#memory_total=310.5MB sample#memory_quota=512.00MB"
    );
  });

  test("stops at a malformed frame instead of misreading the rest", () => {
    expect(parseLogplex(enc.encode("garbage"))).toEqual([]);
  });
});

describe("object keys", () => {
  const first = Date.UTC(2026, 9, 19, 20, 1, 51, 596);
  const last = Date.UTC(2026, 9, 19, 20, 2, 50, 12);

  test("file under the hour of the first line and round-trip the range", () => {
    const key = objectKey("motzi", first, last, "ab12cd34");
    expect(key).toBe(
      "motzi/2026/10/19/20/20261019T200151596Z-20261019T200250012Z-ab12cd34.log"
    );
    expect(key.startsWith(hourPrefix("motzi", first))).toBe(true);
    expect(keyRange(key)).toEqual({ first, last });
  });

  test("batchRange uses the earliest and latest line times", () => {
    const lines = [
      "2026-10-19T20:02:00+00:00 app[web.1]: b",
      "2026-10-19T20:01:00+00:00 app[worker.1]: a",
      "no timestamp",
    ];
    const fallback = Date.UTC(2026, 9, 19, 20, 1, 30);
    expect(batchRange(lines, fallback)).toEqual({
      first: Date.UTC(2026, 9, 19, 20, 1),
      last: Date.UTC(2026, 9, 19, 20, 2),
    });
  });
});

describe("reading", () => {
  const now = Date.UTC(2026, 9, 19, 21, 0);

  test("parseSince takes relative and absolute times", () => {
    expect(parseSince("30m", now)).toBe(now - 30 * 60_000);
    expect(parseSince("2h", now)).toBe(now - 2 * 3_600_000);
    expect(parseSince("1d", now)).toBe(now - 86_400_000);
    expect(parseSince("2026-10-19T20:00:00Z", now)).toBe(
      Date.UTC(2026, 9, 19, 20)
    );
    expect(parseSince("soon", now)).toBeNull();
  });

  test("filterLines keeps the window and matches the query case-insensitively", () => {
    const lines = [
      "2026-10-19T19:59:59+00:00 app[web.1]: too early",
      "2026-10-19T20:10:00+00:00 heroku[router]: status=500 path=/menu",
      "2026-10-19T20:20:00+00:00 heroku[router]: status=200 path=/menu",
    ];
    const since = Date.UTC(2026, 9, 19, 20);
    expect(filterLines(lines, since, now, null)).toEqual(lines.slice(1));
    expect(filterLines(lines, since, now, "STATUS=500")).toEqual([lines[1]]);
  });
});
