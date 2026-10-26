import React from "react";
import { afterEach, beforeAll, beforeEach, mock } from "bun:test";
import { cleanup, configure } from "@testing-library/react";
import { resetNow } from "./support/clock";
import stripeMock, {
  ahoyMock,
  elementsMock,
  expressCheckout,
  paymentElementMock,
  recordElementsOptions,
  resetStripeMock,
  stripeLoader,
} from "./menu/stripeMock";

// Pin luxon "now" to FIXED_NOW (see support/clock.ts). Set at preload
// time too, so module-level fixtures computed on import are deterministic.
// Tests that need a different time use `withNow(...)` or `setNow(...)`; the
// hooks below restore the fixed time around every test.
resetNow();
beforeEach(() => {
  resetNow();
});
afterEach(() => {
  resetNow();
});

// Give waitFor/findBy headroom on slow CI runners (#364), but keep it below
// bun's 5s per-test timeout. If they were equal, bun would kill a stuck test
// before testing-library threw its "Unable to find…" error with the DOM dump.
configure({ asyncUtilTimeout: 3000 });

// Stripe Elements render cross-origin iframes, so they're stood in for by
// plain inputs. useStripe/useElements hand out the shared mocks in
// stripeMock.ts, which also keeps the last <Elements> options.

const Elements: React.FC<{ children?: React.ReactNode; options?: unknown }> = ({
  children,
  options,
}) => {
  recordElementsOptions(options);
  return <div data-testid="stripe-elements">{children}</div>;
};

const PaymentElement: React.FC<{
  onChange?: (event: { complete: boolean }) => void;
  onLoadError?: (event: { error: { message: string } }) => void;
}> = ({ onChange, onLoadError }) => {
  // Like Stripe's, it reports a load error once, as it mounts.
  React.useEffect(() => {
    const error = paymentElementMock.loadError;
    if (error) onLoadError?.({ error });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  return (
    <input
      data-testid="payment-element"
      aria-label="Card details"
      onChange={() => onChange?.({ complete: true })}
    />
  );
};

// Clicking it plays the wallet flow: onClick must resolve before the sheet
// "opens", then the customer authorizes and onConfirm runs.
const ExpressCheckoutElement: React.FC<{
  onClick?: (event: { resolve: () => void }) => void;
  onConfirm?: (event: { paymentFailed: () => void }) => void;
}> = ({ onClick, onConfirm }) => (
  <button
    type="button"
    data-testid="express-checkout"
    onClick={() => {
      let resolved = false;
      onClick?.({ resolve: () => (resolved = true) });
      if (resolved) {
        onConfirm?.({ paymentFailed: () => expressCheckout.paymentFailed() });
      }
    }}
  >
    Express checkout
  </button>
);

mock.module("@stripe/react-stripe-js", () => ({
  Elements,
  useStripe: () => stripeMock,
  useElements: () => elementsMock,
  PaymentElement,
  ExpressCheckoutElement,
}));

mock.module("@stripe/stripe-js", () => ({
  loadStripe: mock(() => Promise.resolve(stripeMock)),
}));
mock.module("@stripe/stripe-js/pure", () => ({
  loadStripe: (key: string) => stripeLoader.loadStripe(key),
}));

// ahoy.js posts events to /ahoy/events; tests inspect ahoyMock instead.
mock.module("ahoy.js", () => ({ default: ahoyMock }));

beforeEach(() => {
  resetStripeMock();
  ahoyMock.track = mock(() => {});
});

beforeAll(() => {
  window.alert = mock(() => {});
});

afterEach(() => {
  cleanup();
});
