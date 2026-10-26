import { describe, expect, test } from "bun:test";
import { isRetryable } from "../src/errors";

function doError(props: Record<string, boolean>): Error {
  return Object.assign(
    new Error("Internal error in Durable Object storage"),
    props
  );
}

describe("isRetryable", () => {
  test("retries a transient Durable Object error", () => {
    expect(isRetryable(doError({ retryable: true }))).toBe(true);
  });

  test("doesn't retry an overloaded object", () => {
    expect(isRetryable(doError({ retryable: true, overloaded: true }))).toBe(
      false
    );
  });

  test("doesn't retry ordinary errors", () => {
    expect(isRetryable(new Error("boom"))).toBe(false);
    expect(isRetryable(null)).toBe(false);
  });
});
