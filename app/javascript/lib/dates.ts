// Date helpers for pickup days and deadlines, in the browser's local zone.
//
// Locale is pinned to en-US: callers switch on English weekday names
// (shortDay) and the UI copy is English, so a browser set to another
// language must not localize "Wednesday".
import { DateTime } from "luxon";

export function parse(iso: string): DateTime {
  return DateTime.fromISO(iso, { locale: "en-US" });
}

/** "Wednesday" */
export function weekday(iso: string): string {
  return parse(iso).toFormat("cccc");
}

/** "Wed, Oct 21" */
export function shortDate(dt: DateTime): string {
  return dt.toFormat("ccc, LLL d");
}

/** "3p", "9a", "3:30p" */
export function shortTime(dt: DateTime): string {
  const hourMinutes = dt.minute === 0 ? dt.toFormat("h") : dt.toFormat("h:mm");
  return hourMinutes + (dt.hour < 12 ? "a" : "p");
}

/** Value for an <input type="datetime-local">: "2026-10-21T15:00" */
export function toDateTimeLocal(dt: DateTime): string {
  return dt.toFormat("yyyy-LL-dd'T'HH:mm");
}

export function isPast(iso: string): boolean {
  return DateTime.now().toMillis() > parse(iso).toMillis();
}
