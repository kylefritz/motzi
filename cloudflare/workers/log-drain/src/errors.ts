// Durable Object errors carry `retryable` when the failure was transient
// (e.g. an internal error or a reset). `overloaded` errors also set it, but
// retrying those only adds load.
export function isRetryable(err: unknown): boolean {
  const e = err as { retryable?: boolean; overloaded?: boolean } | null;
  return e?.retryable === true && e.overloaded !== true;
}
