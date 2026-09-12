export type HttpErrorContext = {
  kind: string;
  status?: number;
  message?: string;
  online: boolean;
};

// Context for reporting a failed API call. Keeps the server's status and its
// `{ message }` body so an error event says *why* the request was rejected,
// not just "Request failed with status code 422".
export function httpErrorContext(kind: string, error: unknown): HttpErrorContext {
  const response = (error as { response?: { status?: number; data?: unknown } })
    ?.response;
  const data = response?.data;
  const message =
    data && typeof data === "object" && "message" in data
      ? String((data as { message: unknown }).message)
      : undefined;

  return {
    kind,
    status: response?.status,
    message,
    online: typeof navigator !== "undefined" ? navigator.onLine : true,
  };
}
