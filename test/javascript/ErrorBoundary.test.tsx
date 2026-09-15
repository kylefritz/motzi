import React from "react";
import {
  afterEach,
  beforeEach,
  expect,
  mock,
  spyOn,
  test,
  type Mock,
} from "bun:test";
import { render, screen } from "@testing-library/react";

const reportError = mock((_payload: Record<string, unknown>) => {});

mock.module("../../app/javascript/lib/errorReporter", () => ({
  reportError,
  reportException: () => {},
  installGlobalErrorReporter: () => {},
}));

let consoleError: Mock<typeof console.error>;

beforeEach(() => {
  reportError.mockClear();
  // React logs every error caught by a boundary via console.error. Silence it
  // for this file only — these errors are thrown on purpose.
  consoleError = spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  consoleError.mockRestore();
});

class PaymentError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "PaymentError";
  }
}

function Boom({ error }: { error: Error }): React.ReactElement {
  throw error;
}

async function loadErrorBoundary() {
  const { default: ErrorBoundary } = await import(
    "../../app/javascript/packs/ErrorBoundary"
  );
  return ErrorBoundary;
}

test("renders children when nothing throws", async () => {
  const ErrorBoundary = await loadErrorBoundary();
  render(
    <ErrorBoundary>
      <p>all good</p>
    </ErrorBoundary>
  );

  expect(screen.getByText("all good")).toBeTruthy();
  expect(screen.queryByText("There was an error in this software :(")).toBeNull();
  expect(reportError).not.toHaveBeenCalled();
});

test("renders the fallback and reports when a child throws", async () => {
  const ErrorBoundary = await loadErrorBoundary();
  render(
    <ErrorBoundary>
      <Boom error={new PaymentError("card declined")} />
    </ErrorBoundary>
  );

  expect(screen.getByText("There was an error in this software :(")).toBeTruthy();
  expect(screen.getByText("Please try again or try back later.")).toBeTruthy();
  expect(screen.getByText("card declined")).toBeTruthy();

  expect(reportError).toHaveBeenCalledTimes(1);
  const payload = reportError.mock.calls[0][0];
  expect(payload).toMatchObject({
    error_class: "PaymentError",
    message: "card declined",
    url: location.pathname,
    context: { kind: "react_error_boundary" },
  });
  expect(payload.stack).toContain("card declined");
  expect(payload.stack).toContain("React component stack:");
});

test("falls back to generic class and message for bare errors", async () => {
  const ErrorBoundary = await loadErrorBoundary();
  const bare = new Error("");
  bare.name = "";
  render(
    <ErrorBoundary>
      <Boom error={bare} />
    </ErrorBoundary>
  );

  expect(screen.getByText("There was an error in this software :(")).toBeTruthy();
  expect(reportError).toHaveBeenCalledTimes(1);
  expect(reportError.mock.calls[0][0]).toMatchObject({
    error_class: "Error",
    message: "Unknown error",
  });
});
