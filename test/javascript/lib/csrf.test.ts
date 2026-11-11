import { afterEach, expect, test } from "bun:test";
import type { AxiosRequestConfig } from "axios";

import { csrfToken, installCsrfHeader } from "../../../app/javascript/lib/csrf";

type Interceptor = (config: AxiosRequestConfig) => AxiosRequestConfig;

// A stand-in for axios that keeps the installed request interceptor, so the
// test doesn't depend on the process-wide axios mocks in other test files.
function installOnFakeClient(): Interceptor {
  let interceptor: Interceptor | undefined;
  const client = {
    interceptors: {
      request: {
        use: (fn: Interceptor) => {
          interceptor = fn;
          return 0;
        },
      },
    },
  };
  installCsrfHeader(
    client as unknown as Parameters<typeof installCsrfHeader>[0]
  );
  if (!interceptor) throw new Error("installCsrfHeader added no interceptor");
  return interceptor;
}

function setToken(token: string) {
  const meta = document.createElement("meta");
  meta.setAttribute("name", "csrf-token");
  meta.setAttribute("content", token);
  document.head.appendChild(meta);
}

afterEach(() => {
  document
    .querySelectorAll('meta[name="csrf-token"]')
    .forEach((el) => el.remove());
});

test("csrfToken reads the Rails meta tag", () => {
  expect(csrfToken()).toBeNull();
  setToken("token-123");
  expect(csrfToken()).toBe("token-123");
});

test("adds X-CSRF-Token to same-origin requests and keeps other headers", () => {
  const intercept = installOnFakeClient();
  setToken("token-123");

  const config = intercept({
    method: "post",
    url: "/admin/pickup_days.json",
    headers: { Accept: "application/json" },
  });

  expect(config.headers).toEqual({
    Accept: "application/json",
    "X-CSRF-Token": "token-123",
  });
});

test("reads the token on each request, not at install", () => {
  const intercept = installOnFakeClient();
  setToken("first");
  expect(intercept({ url: "/admin/a.json" }).headers["X-CSRF-Token"]).toBe(
    "first"
  );

  document.querySelector('meta[name="csrf-token"]')?.remove();
  setToken("second");
  expect(intercept({ url: "/admin/a.json" }).headers["X-CSRF-Token"]).toBe(
    "second"
  );
});

test("sends no header without a meta tag", () => {
  const intercept = installOnFakeClient();
  expect(intercept({ url: "/admin/a.json" }).headers).toBeUndefined();
});

test("never sends the token to another origin", () => {
  const intercept = installOnFakeClient();
  setToken("token-123");

  expect(intercept({ url: "https://example.com/x" }).headers).toBeUndefined();
  expect(intercept({ url: "//example.com/x" }).headers).toBeUndefined();
});
