import { expect, test } from "bun:test";

import { httpErrorContext } from "../../../app/javascript/lib/httpErrorContext";

const axiosError = (status: number, data: unknown) =>
  Object.assign(new Error(`Request failed with status code ${status}`), {
    response: { status, data },
  });

test("httpErrorContext keeps the server's status and message", () => {
  const err = axiosError(422, { message: "ordering for this menu is closed" });

  expect(httpErrorContext("create_order", err)).toEqual({
    kind: "create_order",
    status: 422,
    message: "ordering for this menu is closed",
    online: expect.any(Boolean),
    severity: "warning",
  });
});

test("httpErrorContext reports a 4xx card decline as a warning", () => {
  const err = axiosError(422, { message: "Your card was declined." });

  expect(httpErrorContext("create_order", err).severity).toBe("warning");
  expect(httpErrorContext("create_order", axiosError(400, {})).severity).toBe(
    "warning",
  );
});

test("httpErrorContext leaves 5xx and network failures at error severity", () => {
  expect(
    httpErrorContext("create_order", axiosError(500, {})).severity,
  ).toBeUndefined();
  expect(
    httpErrorContext("create_order", new Error("Network Error")).severity,
  ).toBeUndefined();
});

test("httpErrorContext leaves status and message out for a network failure", () => {
  const ctx = httpErrorContext("create_order", new Error("Network Error"));

  expect(ctx.kind).toBe("create_order");
  expect(ctx.status).toBeUndefined();
  expect(ctx.message).toBeUndefined();
  expect(typeof ctx.online).toBe("boolean");
});

test("httpErrorContext tolerates a non-JSON error body", () => {
  const ctx = httpErrorContext("create_order", axiosError(500, "<html>boom</html>"));

  expect(ctx.status).toBe(500);
  expect(ctx.message).toBeUndefined();
});
