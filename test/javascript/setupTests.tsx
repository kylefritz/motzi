import React from "react";
import { afterEach, beforeAll, mock } from "bun:test";
import { cleanup } from "@testing-library/react";

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
