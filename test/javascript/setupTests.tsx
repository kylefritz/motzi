import React from "react";

jest.mock("react-stripe-elements", () => {
  const mockStripe = {
    createToken: jest.fn(() => Promise.resolve({ token: { id: "test_id" } })),
  };

  return {
    Elements: ({ children }) => (
      <div data-testid="stripe-elements">{children}</div>
    ),
    StripeProvider: ({ children }) => (
      <div data-testid="stripe-provider">{children}</div>
    ),
    injectStripe: (Component) => (props) =>
      <Component {...props} stripe={mockStripe} />,
    CardElement: ({ onChange }) => (
      <input
        data-testid="card-element"
        onChange={() => onChange && onChange({ complete: true })}
      />
    ),
    PaymentRequestButtonElement: () => null,
  };
});

beforeAll(() => {
  window.alert = jest.fn();
});
