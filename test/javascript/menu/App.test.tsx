import React from "react";
import { afterEach, beforeEach, expect, mock, test } from "bun:test";
import { cleanup, render, screen, waitFor } from "@testing-library/react";

import mockMenuJson from "./mockMenuJson";

const menuResponse = mockMenuJson();

const getMock = mock(() => Promise.resolve({ data: menuResponse }));

mock.module("axios", () => ({
  default: Object.assign(mock(() => Promise.resolve({ data: menuResponse })), {
    get: getMock,
  }),
}));

const reportExceptionMock = mock(
  (_err: unknown, _context?: Record<string, unknown>) => {}
);

// Three levels up — test/javascript/menu → repo root. A 2-up path would
// resolve to a nonexistent file and the mock would silently not intercept.
mock.module("../../../app/javascript/lib/errorReporter", () => ({
  reportException: reportExceptionMock,
  reportError: () => {},
  installGlobalErrorReporter: () => {},
}));

const networkError = (message: string) => () =>
  Promise.reject(new Error(message)); // no .response — axios network failure

afterEach(cleanup);

beforeEach(() => {
  getMock.mockClear();
  getMock.mockImplementation(() => Promise.resolve({ data: menuResponse }));
  reportExceptionMock.mockClear();
  window.history.pushState({}, "", "/menu");
});

test("retries a network error and recovers without reporting", async () => {
  getMock.mockImplementationOnce(networkError("Network Error recovers"));
  const { default: App } = await import("menu/App");

  render(<App />);

  await waitFor(() => expect(getMock).toHaveBeenCalledTimes(2), {
    timeout: 3000,
  });
  await waitFor(() =>
    expect(screen.queryByText("We can't load the menu")).toBeNull()
  );
  expect(reportExceptionMock).not.toHaveBeenCalled();
});

test("reports and shows error once retries are exhausted", async () => {
  getMock.mockImplementation(networkError("Network Error exhausted"));
  const { default: App } = await import("menu/App");

  render(<App />);

  await waitFor(
    () => expect(screen.getByText("We can't load the menu")).toBeTruthy(),
    { timeout: 5000 }
  );
  expect(getMock).toHaveBeenCalledTimes(3);
  expect(reportExceptionMock).toHaveBeenCalledTimes(1);

  const context = reportExceptionMock.mock.calls[0][1]!;
  expect(context.kind).toBe("menu_fetch");
  expect(context.attempts).toBe(3);
  expect(typeof context.online).toBe("boolean");
});

test("does not retry HTTP errors", async () => {
  getMock.mockImplementation(() => {
    const err = new Error("Request failed with status code 500") as Error & {
      response?: { status: number };
    };
    err.response = { status: 500 };
    return Promise.reject(err);
  });
  const { default: App } = await import("menu/App");

  render(<App />);

  await waitFor(() =>
    expect(screen.getByText("We can't load the menu")).toBeTruthy()
  );
  expect(getMock).toHaveBeenCalledTimes(1);
  expect(reportExceptionMock).toHaveBeenCalledTimes(1);
});
