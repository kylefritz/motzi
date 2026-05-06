// Self-hosted browser error reporter. Posts to /error_events.
// All failures are swallowed — the reporter must never break the page.

type ReportPayload = {
  error_class: string;
  message: string;
  stack: string;
  url: string;
  context?: Record<string, unknown>;
};

const ENDPOINT = "/error_events";
const DEDUPE_WINDOW_MS = 10_000;
const DEDUPE_MAX = 20;

const recent: Array<{ key: string; ts: number }> = [];

function dedupeKey(p: ReportPayload): string {
  const stackHead = (p.stack || "").split("\n").slice(0, 2).join("|");
  return [p.error_class, p.message, stackHead, p.url].join("::");
}

function shouldDrop(p: ReportPayload): boolean {
  const now = Date.now();
  while (recent.length && now - recent[0].ts > DEDUPE_WINDOW_MS) {
    recent.shift();
  }
  const key = dedupeKey(p);
  if (recent.some((r) => r.key === key)) {
    return true;
  }
  recent.push({ key, ts: now });
  while (recent.length > DEDUPE_MAX) {
    recent.shift();
  }
  return false;
}

function csrfToken(): string | null {
  const el = document.querySelector('meta[name="csrf-token"]');
  return el ? el.getAttribute("content") : null;
}

export function reportError(payload: ReportPayload): void {
  try {
    if (shouldDrop(payload)) return;

    const body = JSON.stringify(payload);
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      Accept: "application/json",
    };
    const token = csrfToken();
    if (token) headers["X-CSRF-Token"] = token;

    if (typeof fetch === "function") {
      fetch(ENDPOINT, {
        method: "POST",
        headers,
        body,
        credentials: "same-origin",
        keepalive: true,
      }).catch(() => {
        /* swallow */
      });
    } else if (
      typeof navigator !== "undefined" &&
      typeof navigator.sendBeacon === "function"
    ) {
      const blob = new Blob([body], { type: "application/json" });
      navigator.sendBeacon(ENDPOINT, blob);
    }
  } catch {
    /* swallow — reporter must never break the page */
  }
}

export function reportException(
  error: unknown,
  context: Record<string, unknown> = {},
): void {
  try {
    const e = error as Error & { name?: string };
    reportError({
      error_class: (e && e.name) || "Error",
      message: (e && e.message) || String(error),
      stack: (e && e.stack) || "",
      url: typeof location !== "undefined" ? location.pathname : "",
      context,
    });
  } catch {
    /* swallow */
  }
}

let installed = false;

export function installGlobalErrorReporter(): void {
  if (installed || typeof window === "undefined") return;
  installed = true;

  window.addEventListener("error", (event: ErrorEvent) => {
    const err = event.error as Error | undefined;
    reportError({
      error_class: (err && err.name) || "Error",
      message: (err && err.message) || event.message || "Unknown error",
      stack: (err && err.stack) || "",
      url: location.pathname,
      context: {
        kind: "window.onerror",
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
      },
    });
  });

  window.addEventListener(
    "unhandledrejection",
    (event: PromiseRejectionEvent) => {
      const reason = event.reason as Error | undefined;
      reportError({
        error_class:
          (reason && (reason as Error).name) || "UnhandledPromiseRejection",
        message:
          (reason && (reason as Error).message) ||
          (typeof reason === "string" ? reason : "Unhandled promise rejection"),
        stack: (reason && (reason as Error).stack) || "",
        url: location.pathname,
        context: { kind: "unhandledrejection" },
      });
    },
  );
}
