import { describe, expect, test } from "bun:test";
import { DateTime } from "luxon";
import moment from "moment";

import { FIXED_NOW, now, setNow, withNow } from "../support/clock";

describe("test clock", () => {
  test("pins luxon and moment to FIXED_NOW by default", () => {
    expect(DateTime.now().toMillis()).toBe(FIXED_NOW);
    expect(moment().valueOf()).toBe(FIXED_NOW);
    expect(now().toMillis()).toBe(FIXED_NOW);
  });

  test("does not freeze the global Date", () => {
    expect(Math.abs(Date.now() - FIXED_NOW)).toBeGreaterThan(0);
  });

  test("setNow overrides for the rest of the test", () => {
    setNow("2030-05-01T09:00:00Z");
    expect(moment().toISOString()).toBe("2030-05-01T09:00:00.000Z");
    expect(DateTime.now().toUTC().toISO()).toBe("2030-05-01T09:00:00.000Z");
  });

  test("setNow from a previous test is reset", () => {
    expect(moment().valueOf()).toBe(FIXED_NOW);
  });

  test("withNow restores the previous time (sync, throw, async)", async () => {
    const inside = withNow("2027-01-01T00:00:00Z", () => moment().valueOf());
    expect(inside).toBe(Date.parse("2027-01-01T00:00:00Z"));
    expect(moment().valueOf()).toBe(FIXED_NOW);

    expect(() =>
      withNow("2027-01-01T00:00:00Z", () => {
        throw new Error("boom");
      })
    ).toThrow("boom");
    expect(moment().valueOf()).toBe(FIXED_NOW);

    const asyncInside = await withNow(
      DateTime.fromISO("2028-01-01T00:00:00Z"),
      async () => {
        await Promise.resolve();
        return DateTime.now().toMillis();
      }
    );
    expect(asyncInside).toBe(Date.parse("2028-01-01T00:00:00Z"));
    expect(DateTime.now().toMillis()).toBe(FIXED_NOW);
  });
});
