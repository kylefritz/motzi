import React from "react";
import { afterEach, beforeAll, mock } from "bun:test";
import { cleanup } from "@testing-library/react";

type StripeToken = { token: { id: string } };

const createToken = mock(() => Promise.resolve({ token: { id: "test_id" } }));

const mockStripe = {
  createToken,
};

const Elements: React.FC<{ children?: React.ReactNode }> = ({ children }) => (
  <div data-testid="stripe-elements">{children}</div>
);

const StripeProvider: React.FC<{ children?: React.ReactNode }> = ({
  children,
}) => <div data-testid="stripe-provider">{children}</div>;

const injectStripe =
  <P extends object>(
    Component: React.ComponentType<P & { stripe: typeof mockStripe }>
  ) =>
  (props: P) =>
    <Component {...props} stripe={mockStripe} />;

const CardElement: React.FC<{ onChange?: (event: { complete: boolean }) => void }> = ({
  onChange,
}) => (
  <input
    data-testid="card-element"
    onChange={() => onChange?.({ complete: true })}
  />
);

const PaymentRequestButtonElement: React.FC = () => null;

mock.module("react-stripe-elements", () => ({
  Elements,
  StripeProvider,
  injectStripe,
  CardElement,
  PaymentRequestButtonElement,
}));

beforeAll(() => {
  window.alert = mock(() => {});
});

afterEach(() => {
  cleanup();
});
