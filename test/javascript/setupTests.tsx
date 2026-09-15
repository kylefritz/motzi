import React from "react";
import { afterEach, beforeAll, mock } from "bun:test";
import { cleanup, configure } from "@testing-library/react";

// Give waitFor/findBy headroom on slow CI runners (#364), but keep it below
// bun's 5s per-test timeout. If they were equal, bun would kill a stuck test
// before testing-library threw its "Unable to find…" error with the DOM dump.
configure({ asyncUtilTimeout: 3000 });

type StripeToken = { token: { id: string } };

const createToken = mock(() =>
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
