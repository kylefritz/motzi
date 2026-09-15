export type HttpErrorContext = {
  kind: string;
  status?: number;
  message?: string;
  online: boolean;
  severity?: "warning";
};

// Context for reporting a failed API call. Keeps the server's status and its
// `{ message }` body so an error event says *why* the request was rejected,
// not just "Request failed with status code 422".
//
// A 4xx means the server rejected the request on purpose (a Stripe card
// decline, ordering closed) — tagged severity "warning" so the anomaly feed
// lists it under Rejected Requests instead of as an application failure.
// Server-side events use the same context.severity key.
export function httpErrorContext(kind: string, error: unknown): HttpErrorContext {
  const response = (error as { response?: { status?: number; data?: unknown } })
    ?.response;
  const data = response?.data;
  const message =
    data && typeof data === "object" && "message" in data
      ? String((data as { message: unknown }).message)
      : undefined;
  const status = response?.status;

  return {
    kind,
    status,
    message,
    online: typeof navigator !== "undefined" ? navigator.onLine : true,
    ...(isClientError(status) ? { severity: "warning" as const } : {}),
  };
}

function isClientError(status: number | undefined): boolean {
  return status !== undefined && status >= 400 && status < 500;
}
