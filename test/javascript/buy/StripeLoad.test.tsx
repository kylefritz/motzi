import React from "react";
import { beforeEach, expect, mock, test } from "bun:test";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import stripeMock, {
  ahoyMock,
  paymentElementMock,
  stripeLoader,
} from "../menu/stripeMock";

// error_events #3136, #3137, #3203, #3271: "Failed to load Stripe.js" was an
// unhandled rejection, and the card form stayed blank with no explanation.

const reportError = mock((_payload: Record<string, unknown>) => {});
mock.module("../../../app/javascript/lib/errorReporter", () => ({
  reportError,
  reportException: () => {},
  installGlobalErrorReporter: () => {},
}));

const { default: Payment, LOAD_FAILED_MESSAGE } =
  await import("../../../app/javascript/packs/buy/Payment");
const { stripeLoadRetry } =
  await import("../../../app/javascript/packs/buy/stripeLoad");

const loadFailure = () => Promise.reject(new Error("Failed to load Stripe.js"));

function renderPayment() {
  return render(
    <Payment
      price={10}
      stripeApiKey="pk_test_123"
      onPay={() => Promise.resolve({})}
      submitting={false}
    />
  );
}

function trackedSteps(): string[] {
  return ahoyMock.track.mock.calls
    .filter(([name]) => name === "stripe_load")
    .map(([, props]) => props?.step as string);
}

beforeEach(() => {
  stripeLoadRetry.delayMs = 0;
  reportError.mockClear();
});

test("loads Stripe.js once and shows the card form", async () => {
  renderPayment();

  expect(await screen.findByTestId("payment-element")).toBeTruthy();
  expect(stripeLoader.loadStripe).toHaveBeenCalledTimes(1);
  expect(stripeLoader.loadStripe).toHaveBeenCalledWith("pk_test_123");
  expect(trackedSteps()).toEqual([]);
  expect(reportError).not.toHaveBeenCalled();
});

test("retries a failed load by itself and tracks the recovery", async () => {
  stripeLoader.loadStripe
    .mockImplementationOnce(loadFailure)
    .mockImplementationOnce(() => Promise.resolve(stripeMock));
  renderPayment();

  await waitFor(() =>
    expect(trackedSteps()).toEqual(["script_failed", "recovered"])
  );
  expect(stripeLoader.loadStripe).toHaveBeenCalledTimes(2);
  expect(screen.queryByText(LOAD_FAILED_MESSAGE)).toBeNull();
  expect(screen.getByTestId("payment-element")).toBeTruthy();
  expect(reportError).not.toHaveBeenCalled();
});

test("explains a load that keeps failing, reports it, and tries again on request", async () => {
  stripeLoader.loadStripe.mockImplementation(loadFailure);
  renderPayment();

  expect(await screen.findByText(LOAD_FAILED_MESSAGE)).toBeTruthy();
  expect(screen.queryByTestId("payment-element")).toBeNull();
  expect(trackedSteps()).toEqual(["script_failed", "script_failed", "gave_up"]);
  expect(reportError).toHaveBeenCalledTimes(1);
  const report = reportError.mock.calls[0][0];
  expect(report.error_class).toBe("StripeLoadError");
  expect(report.context).toMatchObject({
    kind: "stripe_load",
    stage: "script",
  });

  // The connection is back; Try again loads it.
  stripeLoader.loadStripe.mockImplementation(() => Promise.resolve(stripeMock));
  await userEvent.click(screen.getByRole("button", { name: "Try again" }));

  expect(await screen.findByTestId("payment-element")).toBeTruthy();
  expect(screen.queryByText(LOAD_FAILED_MESSAGE)).toBeNull();
  expect(trackedSteps()).toContain("retry_clicked");
  const retry = ahoyMock.track.mock.calls.find(
    ([, props]) => props?.step === "retry_clicked"
  );
  expect(retry?.[1]).toMatchObject({ attempt: 1 });
});

test("explains a card form that fails to load after Stripe.js did", async () => {
  paymentElementMock.loadError = { message: "Element failed" };
  renderPayment();

  expect(await screen.findByText(LOAD_FAILED_MESSAGE)).toBeTruthy();
  expect(trackedSteps()).toEqual(["element_failed"]);
  expect(reportError).toHaveBeenCalledTimes(1);
  expect(reportError.mock.calls[0][0].context).toMatchObject({
    stage: "element",
  });

  paymentElementMock.loadError = null;
  await userEvent.click(screen.getByRole("button", { name: "Try again" }));
  expect(await screen.findByTestId("payment-element")).toBeTruthy();
});
