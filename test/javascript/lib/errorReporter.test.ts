import {
  afterEach,
  beforeEach,
  describe,
  expect,
  mock,
  setSystemTime,
  spyOn,
  test,
} from "bun:test";

// Tests the real errorReporter module. Several other test files replace it via
// mock.module(...), which is process-wide in bun, so we import it with a
// unique query string: that bypasses the module mock and gives each test a
// fresh copy (resetting the module-level dedupe buffer and `installed` flag).
// The key is random rather than a counter so `bun test --rerun-each` (which
// re-evaluates this file but keeps the module cache) still gets fresh copies.
type Reporter = typeof import("../../../app/javascript/lib/errorReporter");

function loadReporter(): Promise<Reporter> {
  return import(
    `../../../app/javascript/lib/errorReporter.ts?test=${crypto.randomUUID()}`
  ) as Promise<Reporter>;
}

type FetchArgs = [input: string, init: RequestInit];
const originalFetch = globalThis.fetch;
let fetchMock: ReturnType<typeof mock<(...args: FetchArgs) => Promise<Response>>>;

function requests() {
  return fetchMock.mock.calls.map(([url, init]) => ({
    url,
    init,
    headers: init.headers as Record<string, string>,
    body: JSON.parse(init.body as string),
  }));
}

function lastRequest() {
  const all = requests();
  return all[all.length - 1];
}

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

const payload = (overrides: Record<string, unknown> = {}) => ({
  error_class: "TypeError",
  message: "x is undefined",
  stack: "TypeError: x is undefined\n    at menu.js:1:1\n    at menu.js:2:2",
  url: "/menu",
  context: { kind: "test" },
  ...overrides,
});

beforeEach(() => {
  fetchMock = mock((..._args: FetchArgs) =>
    Promise.resolve(new Response(null, { status: 201 }))
  );
  globalThis.fetch = fetchMock as unknown as typeof fetch;
});

afterEach(() => {
  globalThis.fetch = originalFetch;
  setSystemTime();
  document.head
    .querySelectorAll('meta[name="csrf-token"]')
    .forEach((el) => el.remove());
});

describe("reportError", () => {
  test("POSTs the payload as JSON to /error_events", async () => {
    const { reportError } = await loadReporter();
    reportError(payload());

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const req = lastRequest();
    expect(req.url).toBe("/error_events");
    expect(req.init).toMatchObject({
      method: "POST",
      credentials: "same-origin",
      keepalive: true,
    });
    expect(req.headers).toEqual({
      "Content-Type": "application/json",
      Accept: "application/json",
    });
    expect(req.body).toEqual(payload());
  });

  test("forwards the CSRF token when a meta tag is present", async () => {
    const meta = document.createElement("meta");
    meta.setAttribute("name", "csrf-token");
    meta.setAttribute("content", "token-123");
    document.head.appendChild(meta);

    const { reportError } = await loadReporter();
    reportError(payload());

    expect(lastRequest().headers["X-CSRF-Token"]).toBe("token-123");
  });

  test("omits the CSRF header when there is no meta tag", async () => {
    const { reportError } = await loadReporter();
    reportError(payload());

    expect(lastRequest().headers).not.toHaveProperty("X-CSRF-Token");
  });

  test("drops identical errors within the 10s dedupe window", async () => {
    setSystemTime(new Date("2026-01-06T17:00:00Z"));
    const { reportError } = await loadReporter();

    reportError(payload());
    reportError(payload());
    expect(fetchMock).toHaveBeenCalledTimes(1);

    setSystemTime(new Date("2026-01-06T17:00:09Z"));
    reportError(payload());
    expect(fetchMock).toHaveBeenCalledTimes(1);

    setSystemTime(new Date("2026-01-06T17:00:10.001Z"));
    reportError(payload());
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  test("dedupes on class, message, first two stack lines and url", async () => {
    const { reportError } = await loadReporter();

    reportError(payload());
    // Only the third stack line differs: still a duplicate.
    reportError(payload({ stack: `${payload().stack}\n    at other.js:9:9` }));
    // Context is not part of the key.
    reportError(payload({ context: { kind: "other" } }));
    expect(fetchMock).toHaveBeenCalledTimes(1);

    reportError(payload({ message: "y is undefined" }));
    reportError(payload({ url: "/checkout" }));
    reportError(payload({ error_class: "RangeError" }));
    expect(fetchMock).toHaveBeenCalledTimes(4);
  });

  test("swallows fetch rejections", async () => {
    fetchMock.mockImplementation(() => Promise.reject(new Error("offline")));
    const { reportError } = await loadReporter();

    expect(() => reportError(payload())).not.toThrow();
    await flush();
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  test("swallows synchronous fetch errors", async () => {
    fetchMock.mockImplementation(() => {
      throw new Error("blocked");
    });
    const { reportError } = await loadReporter();

    expect(() => reportError(payload())).not.toThrow();
  });

  test("falls back to sendBeacon when fetch is unavailable", async () => {
    globalThis.fetch = undefined as unknown as typeof fetch;
    const nav = navigator as Navigator & { sendBeacon?: unknown };
    const originalBeacon = nav.sendBeacon;
    const sendBeacon = mock((_url: string, _data: Blob) => true);
    nav.sendBeacon = sendBeacon;

    try {
      const { reportError } = await loadReporter();
      reportError(payload());

      expect(sendBeacon).toHaveBeenCalledTimes(1);
      const [url, blob] = sendBeacon.mock.calls[0];
      expect(url).toBe("/error_events");
      expect(blob.type).toMatch(/^application\/json/);
      expect(JSON.parse(await blob.text())).toEqual(payload());
    } finally {
      nav.sendBeacon = originalBeacon;
    }
  });
});

describe("reportException", () => {
  test("builds the payload from an Error", async () => {
    const { reportException } = await loadReporter();
    const error = new RangeError("too many loaves");

    reportException(error, { orderId: 7 });

    expect(lastRequest().body).toEqual({
      error_class: "RangeError",
      message: "too many loaves",
      stack: error.stack,
      url: location.pathname, // other test files pushState, so not always "/"
      context: { orderId: 7 },
    });
  });

  test("handles non-Error values", async () => {
    const { reportException } = await loadReporter();

    reportException("something broke");

    expect(lastRequest().body).toEqual({
      error_class: "Error",
      message: "something broke",
      stack: "",
      url: location.pathname, // other test files pushState, so not always "/"
      context: {},
    });
  });
});

describe("installGlobalErrorReporter", () => {
  // Listeners attach to the shared jsdom window and can't be removed, so a
  // previous run (e.g. --rerun-each) may leave its own listeners behind. We
  // count registrations with a spy and assert on request contents rather than
  // exact fetch call counts.
  test("reports window errors and unhandled rejections, installing once", async () => {
    const { installGlobalErrorReporter } = await loadReporter();
    const addListener = spyOn(window, "addEventListener");
    try {
      installGlobalErrorReporter();
      installGlobalErrorReporter();
      const events = addListener.mock.calls.map(([type]) => type);
      expect(events).toEqual(["error", "unhandledrejection"]);
    } finally {
      addListener.mockRestore();
    }

    const bodies = () => requests().map((r) => r.body);
    const error = new TypeError("window boom");
    window.dispatchEvent(
      new window.ErrorEvent("error", {
        error,
        message: error.message,
        filename: "menu.js",
        lineno: 12,
        colno: 3,
      })
    );

    expect(bodies()).toContainEqual({
      error_class: "TypeError",
      message: "window boom",
      stack: error.stack,
      url: location.pathname, // other test files pushState, so not always "/"
      context: {
        kind: "window.onerror",
        filename: "menu.js",
        lineno: 12,
        colno: 3,
      },
    });

    const rejection = Object.assign(new window.Event("unhandledrejection"), {
      reason: "nope",
    });
    window.dispatchEvent(rejection);

    expect(bodies()).toContainEqual({
      error_class: "UnhandledPromiseRejection",
      message: "nope",
      stack: "",
      url: location.pathname, // other test files pushState, so not always "/"
      context: { kind: "unhandledrejection" },
    });
  });
});
