import React, { useState } from "react";
import {
  ExpressCheckoutElement,
  PaymentElement,
  useElements,
  useStripe,
} from "@stripe/react-stripe-js";
import type {
  StripeExpressCheckoutElementClickEvent,
  StripeExpressCheckoutElementConfirmEvent,
} from "@stripe/stripe-js";
import { formatMoney } from "accounting";

import type {
  PaymentSubmission,
  RequiresActionResponse,
} from "../../types/api";

// Stripe's smallest USD charge (StripeCheckout::MINIMUM_CENTS)
export const MINIMUM_CARD_PAYMENT = 0.5;

// The server answers a card that needs 3D Secure with the intent's client
// secret instead of the order; we finish it here and post again.
export function isRequiresAction(
  result: unknown
): result is RequiresActionResponse {
  return (
    typeof result === "object" &&
    result !== null &&
    (result as RequiresActionResponse).requiresAction === true
  );
}

export type PayProps = {
  // Posts the order or credit purchase. Resolves with the server's response
  // data, which may ask for 3D Secure.
  onPay: (payment: PaymentSubmission) => Promise<unknown>;
  // Checks the rest of the form before paying; false stops the payment.
  canPay?: () => boolean;
  credits?: number;
  submitting: boolean;
  disabled?: boolean;
  // when set, the order can't be paid as is (e.g. below its minimum); shown
  // on the disabled pay button
  blockedText?: string | null;
};

// Paying by card or wallet. Rendered inside Stripe's <Elements> (Payment).
export default function Card({
  onPay,
  canPay = () => true,
  credits,
  price,
  submitting,
  disabled,
  blockedText,
}: PayProps & { price: number | null }) {
  const stripe = useStripe();
  const elements = useElements();
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [waitingOnStripe, setWaitingOnStripe] = useState(false);
  const [cardFilled, setCardFilled] = useState(false);
  const tooSmall =
    price !== null && price < MINIMUM_CARD_PAYMENT
      ? `Card payments start at ${formatMoney(MINIMUM_CARD_PAYMENT)}`
      : null;
  // an empty cart (price null) has nothing to pay for yet
  const blocked =
    blockedText || tooSmall || (price === null ? "Select an item" : null);

  // Pays with what the Payment or Express Checkout Element collected: the
  // server charges a ConfirmationToken, and if the bank wants 3D Secure we run
  // it and hand the server the now-paid PaymentIntent.
  const payWithElements = async (): Promise<string | null> => {
    if (!stripe || !elements) {
      console.log("Stripe.js hasn't loaded yet.");
      return "Card payments aren't ready yet. Please try again.";
    }
    const { error: submitError } = await elements.submit();
    if (submitError) {
      return submitError.message ?? "Check your card details";
    }
    const { error, confirmationToken } = await stripe.createConfirmationToken({
      elements,
    });
    if (error) {
      return error.message ?? "We couldn't read your card";
    }
    const result = await onPay({ confirmationTokenId: confirmationToken.id });
    if (!isRequiresAction(result)) {
      return null;
    }
    console.log("payment requires action");
    const { error: actionError, paymentIntent } = await stripe.handleNextAction(
      { clientSecret: result.clientSecret }
    );
    if (actionError || !paymentIntent) {
      return actionError?.message ?? "We couldn't confirm your card";
    }
    await onPay({ paymentIntentId: paymentIntent.id });
    return null;
  };

  const handleSubmit = async (e: React.SyntheticEvent) => {
    e.preventDefault();
    if (blocked || !canPay()) {
      return;
    }
    setErrorMessage(null);
    setWaitingOnStripe(true);
    try {
      setErrorMessage(await payWithElements());
    } finally {
      setWaitingOnStripe(false);
    }
  };

  // Apple Pay / Google Pay: check the form before the wallet sheet opens.
  const handleExpressClick = (
    event: StripeExpressCheckoutElementClickEvent
  ) => {
    if (blocked || !canPay()) {
      return;
    }
    event.resolve();
  };

  const handleExpressConfirm = async (
    event: StripeExpressCheckoutElementConfirmEvent
  ) => {
    setErrorMessage(null);
    setWaitingOnStripe(true);
    try {
      const message = await payWithElements();
      if (message) {
        event.paymentFailed({ reason: "fail" });
      }
      setErrorMessage(message);
    } finally {
      setWaitingOnStripe(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      {!disabled && !blocked && (
        <div className="mb-3">
          <ExpressCheckoutElement
            onClick={handleExpressClick}
            onConfirm={handleExpressConfirm}
          />
        </div>
      )}
      <h5>Pay by credit card</h5>
      {!disabled && (
        <PaymentElement
          onChange={({ complete }) => setCardFilled(complete)}
          options={{
            layout: "tabs",
            // Apple Pay and Google Pay are in the Express Checkout Element
            wallets: { applePay: "never", googlePay: "never" },
          }}
        />
      )}
      {errorMessage && (
        <div className="error" role="alert">
          {errorMessage}
        </div>
      )}
      <Button
        disabled={!cardFilled || !!blocked}
        spinner={submitting || waitingOnStripe}
        text={
          blocked ||
          [
            `Charge credit card ${formatMoney(price ?? 0)}`,
            credits ? ` for ${credits} credits` : "",
          ].join("")
        }
      />
    </form>
  );
}

// A $0 pay-what-you-can order: nothing to charge, so no Stripe.
export function NoCharge({
  onPay,
  canPay = () => true,
  submitting,
  blockedText,
}: PayProps) {
  const handleClick = (e: React.SyntheticEvent) => {
    e.preventDefault();
    if (blockedText || !canPay()) {
      return;
    }
    onPay({});
  };
  return (
    <Button
      disabled={!!blockedText}
      spinner={submitting}
      text={blockedText || "Submit Order"}
      onClick={handleClick}
    />
  );
}

function Button({
  disabled,
  onClick,
  spinner,
  text,
}: {
  disabled?: boolean;
  onClick?: (event: React.SyntheticEvent) => void;
  spinner: boolean;
  text: string;
}) {
  return (
    <button
      disabled={disabled || spinner}
      className="btn btn-primary btn-lg btn-block"
      style={buttonStyle}
      onClick={onClick}
      type="submit"
    >
      {spinner ? <Spinner /> : text}
    </button>
  );
}
const buttonStyle = {
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
};

function Spinner() {
  return (
    <>
      <span
        className="spinner-border spinner-border-sm mr-2"
        role="status"
        aria-hidden="true"
      />
      Purchasing...
    </>
  );
}
