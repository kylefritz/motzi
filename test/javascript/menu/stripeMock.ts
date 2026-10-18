import { mock, type Mock } from "bun:test";

// The slice of Stripe.js the checkout uses (#412): the deferred-intent
// Payment / Express Checkout Elements flow. setupTests.tsx wires these into
// the @stripe/react-stripe-js mock, so tests can override a result or inspect
// calls here.
export type ConfirmationTokenResult =
  | { confirmationToken: { id: string }; error?: undefined }
  | { confirmationToken?: undefined; error: { message: string } };

export type HandleNextActionResult =
  | { paymentIntent: { id: string; status: string }; error?: undefined }
  | { paymentIntent?: undefined; error: { message: string } };

// The options the most recent <Elements> rendered with (mode, amount...).
export const elementsOptions: { current: unknown } = { current: null };
export function recordElementsOptions(options: unknown) {
  elementsOptions.current = options;
}

// paymentFailed on the Express Checkout Element's confirm event
export const expressCheckout: { paymentFailed: Mock<() => void> } = {
  paymentFailed: mock(() => {}),
};

type SubmitResult = { error?: { message: string } };

export const elementsMock: {
  submit: Mock<() => Promise<SubmitResult>>;
} = {
  submit: mock(() => Promise.resolve({})),
};

const stripeMock: {
  createConfirmationToken: Mock<
    (options: { elements: unknown }) => Promise<ConfirmationTokenResult>
  >;
  handleNextAction: Mock<
    (options: { clientSecret: string }) => Promise<HandleNextActionResult>
  >;
} = {
  createConfirmationToken: mock(() =>
    Promise.resolve({ confirmationToken: { id: "ctoken_test" } })
  ),
  handleNextAction: mock(() =>
    Promise.resolve({
      paymentIntent: { id: "pi_test_3ds", status: "succeeded" },
    })
  ),
};

// Back to the default (successful) results, with fresh call logs.
export function resetStripeMock() {
  expressCheckout.paymentFailed = mock(() => {});
  elementsMock.submit = mock(() => Promise.resolve({}));
  stripeMock.createConfirmationToken = mock(() =>
    Promise.resolve({ confirmationToken: { id: "ctoken_test" } })
  );
  stripeMock.handleNextAction = mock(() =>
    Promise.resolve({
      paymentIntent: { id: "pi_test_3ds", status: "succeeded" },
    })
  );
}

export default stripeMock;
