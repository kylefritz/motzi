// Fake "now" for JS tests — the counterpart of Rails' `travel_to`.
//
// setupTests.tsx pins the clock to FIXED_NOW before every test and resets it
// afterwards, so deadline-relative UI states (open / closed / past deadline)
// don't drift with the wall clock.
//
// Why library hooks instead of bun's `setSystemTime`: the app computes
// deadlines with moment (`moment()` in menu/Contexts.ts) and the mocks use
// luxon. Both expose a clock hook (`moment.now`, luxon `Settings.now`), so we
// can pin date math without touching the global `Date`. `setSystemTime`
// freezes `Date.now()` for everything in the process (timers, React, lodash
// debounce/throttle, errorReporter's dedupe window), which is a much bigger
// blast radius than these tests need. Tests that specifically exercise
// `Date.now()` (e.g. errorReporter.test.ts) use `setSystemTime` locally.
import { DateTime, Settings } from "luxon";
import moment from "moment";

// Tuesday 2026-01-06 12:00 America/New_York
export const FIXED_NOW = Date.parse("2026-01-06T17:00:00.000Z");

type Instant = number | string | Date | DateTime;

const momentClock = moment as unknown as { now: () => number };

function toMillis(when: Instant): number {
  if (typeof when === "number") return when;
  if (typeof when === "string") {
    const parsed = DateTime.fromISO(when);
    if (!parsed.isValid) throw new Error(`clock: invalid ISO time ${when}`);
    return parsed.toMillis();
  }
  if (when instanceof Date) return when.getTime();
  return when.toMillis();
}

/** Pin luxon and moment "now" to the given instant. */
export function setNow(when: Instant): void {
  const millis = toMillis(when);
  Settings.now = () => millis;
  momentClock.now = () => millis;
}

/** Restore the default fixed test time. */
export function resetNow(): void {
  setNow(FIXED_NOW);
}

/** The current (fake) time as a luxon DateTime. */
export function now(): DateTime {
  return DateTime.now();
}

/**
 * Run `fn` with "now" set to `when`, then restore the previous time.
 * Works with sync and async callbacks.
 */
export function withNow<T>(when: Instant, fn: () => T): T {
  const previous = Settings.now();
  setNow(when);
  let result: T;
  try {
    result = fn();
  } catch (error) {
    setNow(previous);
    throw error;
  }
  if (result instanceof Promise) {
    return result.finally(() => setNow(previous)) as T;
  }
  setNow(previous);
  return result;
}
