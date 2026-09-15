import React from "react";
import { afterEach, beforeAll, beforeEach, mock } from "bun:test";
import { cleanup, configure } from "@testing-library/react";
import { resetNow } from "./support/clock";
import type { StripeTokenResult } from "./menu/stripeMock";

// Pin luxon/moment "now" to FIXED_NOW (see support/clock.ts). Set at preload
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

const createToken = mock(
  (): Promise<StripeTokenResult> =>
    Promise.resolve({ token: { id: "test_id" }, error: null })
);

const mockStripe = {
  createToken,
};

const mockElements = {
  getElement: mock(() => ({})),
};

const Elements: React.FC<{ children?: React.ReactNode }> = ({ children }) => (
  <div data-testid="stripe-elements">{children}</div>
);

const CardElement: React.FC<{ onChange?: (event: { complete: boolean }) => void }> = ({
  onChange,
}) => (
  <input
    data-testid="card-element"
    onChange={() => onChange?.({ complete: true })}
  />
);

const PaymentRequestButtonElement: React.FC = () => null;

mock.module("@stripe/react-stripe-js", () => ({
  Elements,
  useStripe: () => mockStripe,
  useElements: () => mockElements,
  CardElement,
  PaymentRequestButtonElement,
}));

mock.module("@stripe/stripe-js", () => ({
  loadStripe: mock(() => Promise.resolve(mockStripe)),
}));

beforeAll(() => {
  window.alert = mock(() => {});
});

afterEach(() => {
  cleanup();
});
