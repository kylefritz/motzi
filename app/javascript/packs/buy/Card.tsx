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
  PendingResponse,
  RequiresActionResponse,
} from "../../types/api";

// Stripe's smallest USD charge (StripeCheckout::MINIMUM_CENTS)
export const MINIMUM_CARD_PAYMENT = 0.5;

// After 3D Secure the money has moved; if recording the order keeps failing
// we say so rather than offering to pay again.
export const PAYMENT_RECEIVED_MESSAGE =
  "Payment received, we're finishing your order. Check your email or reload the page in a minute.";
// Waits between retries of that post (tests shorten them).
export const resumeRetry = { delaysMs: [1000, 2000, 4000] };

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

// The payment is still processing; the order is recorded once it succeeds.
export function isPending(result: unknown): result is PendingResponse {
  return (
    typeof result === "object" &&
    result !== null &&
    (result as PendingResponse).pending === true
  );
}

export type PayProps = {
  // Posts the order or credit purchase. Resolves with the server's response
  // data, which may ask for 3D Secure or say the payment is processing. For
  // the post-back after 3D Secure ({ paymentIntentId }) it must reject on
  // failure, so we can retry it instead of offering to pay again.
  onPay: (payment: PaymentSubmission) => Promise<unknown>;
  // Checks the rest of the form before paying; false stops the payment.
  canPay?: () => boolean;
  credits?: number;
  submitting: boolean;
  disabled?: boolean;
  // when set, the order can't be paid as is (e.g. below its minimum); shown
  // on the disabled pay button
  blockedText?: string | null;
  // The amounts the server accepts. Outside them the pay button and wallet
  // are blocked, so the wallet sheet never shows a different amount from
  // what's charged.
  minPrice?: number;
  maxPrice?: number;
};

// What stops a price from being paid by card, if anything.
export function cardPriceProblem(
  price: number | null,
  {
    minPrice = MINIMUM_CARD_PAYMENT,
    maxPrice,
  }: Pick<PayProps, "minPrice" | "maxPrice">
): string | null {
  if (price === null) {
    return "Select an item"; // an empty cart has nothing to pay for yet
  }
  if (!Number.isFinite(price)) {
    return "Enter an amount";
  }
  const min = Math.max(minPrice, MINIMUM_CARD_PAYMENT);
  if (price < min) {
    return `Card payments start at ${formatMoney(min)}`;
  }
  if (maxPrice !== undefined && price > maxPrice) {
    return `The most we can take online is ${formatMoney(maxPrice)}`;
  }
  return null;
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// How a payment attempt ended, for the form to show.
type Outcome = {
  error?: string; // shown; the customer can try again
  submitError?: boolean; // the wallet sheet's details were rejected
  done?: string; // final: the payment went through but the order is pending
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
  minPrice,
  maxPrice,
  onLoadError,
}: PayProps & {
  price: number | null;
  // the card form (Payment Element) couldn't load
  onLoadError?: (error: unknown) => void;
}) {
  const stripe = useStripe();
  const elements = useElements();
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [doneMessage, setDoneMessage] = useState<string | null>(null);
  const [waitingOnStripe, setWaitingOnStripe] = useState(false);
  const [cardFilled, setCardFilled] = useState(false);
  const blocked =
    blockedText || cardPriceProblem(price, { minPrice, maxPrice });
  const busy = submitting || waitingOnStripe;

  // Records the payment the customer just authenticated. It's idempotent on
  // the server, so a failed post is retried with the same intent.
  const finishPaidPayment = async (
    paymentIntentId: string
  ): Promise<Outcome> => {
    for (let attempt = 0; ; attempt++) {
      try {
        const result = await onPay({ paymentIntentId });
        return isPending(result) ? { done: result.message } : {};
      } catch (err) {
        const delay = resumeRetry.delaysMs[attempt];
        if (delay === undefined) {
          console.error("couldn't record a paid payment", paymentIntentId, err);
          return { done: PAYMENT_RECEIVED_MESSAGE };
        }
        console.warn("retrying a paid payment", paymentIntentId, err);
        await sleep(delay);
      }
    }
  };

  // Pays with what the Payment or Express Checkout Element collected: the
  // server charges a ConfirmationToken, and if the bank wants 3D Secure we run
  // it and hand the server the now-paid PaymentIntent.
  const payWithElements = async (): Promise<Outcome> => {
    if (!stripe || !elements) {
      console.log("Stripe.js hasn't loaded yet.");
      return { error: "Card payments aren't ready yet. Please try again." };
    }
    const { error: submitError } = await elements.submit();
    if (submitError) {
      return {
        error: submitError.message ?? "Check your card details",
        submitError: true,
      };
    }
    const { error, confirmationToken } = await stripe.createConfirmationToken({
      elements,
    });
    if (error) {
      return { error: error.message ?? "We couldn't read your card" };
    }
    const result = await onPay({ confirmationTokenId: confirmationToken.id });
    if (isPending(result)) {
      return { done: result.message };
    }
    if (!isRequiresAction(result)) {
      return {}; // placed, or the caller showed why not
    }
    console.log("payment requires action");
    const { error: actionError, paymentIntent } = await stripe.handleNextAction(
      { clientSecret: result.clientSecret }
    );
    if (actionError || !paymentIntent) {
      return { error: actionError?.message ?? "We couldn't confirm your card" };
    }
    return finishPaidPayment(paymentIntent.id);
  };

  const showOutcome = ({ error, done }: Outcome) => {
    setErrorMessage(error ?? null);
    if (done) {
      setDoneMessage(done);
    }
  };

  const handleSubmit = async (e: React.SyntheticEvent) => {
    e.preventDefault();
    if (blocked || busy || doneMessage || !canPay()) {
      return;
    }
    setErrorMessage(null);
    setWaitingOnStripe(true);
    try {
      showOutcome(await payWithElements());
    } finally {
      setWaitingOnStripe(false);
    }
  };

  // Apple Pay / Google Pay: check the form before the wallet sheet opens.
  const handleExpressClick = (
    event: StripeExpressCheckoutElementClickEvent
  ) => {
    if (blocked || busy || doneMessage || !canPay()) {
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
      const outcome = await payWithElements();
      // Only while the sheet is still open, i.e. its details were rejected.
      // After createConfirmationToken the sheet has closed and Stripe.js
      // throws on paymentFailed.
      if (outcome.submitError) {
        event.paymentFailed({ reason: "fail" });
      }
      showOutcome(outcome);
    } finally {
      setWaitingOnStripe(false);
    }
  };

  if (doneMessage) {
    return (
      <div className="alert alert-success" role="status">
        {doneMessage}
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit}>
      {!disabled && !blocked && !busy && (
        <div className="mb-3">
          <ExpressCheckoutElement
            onClick={handleExpressClick}
            onConfirm={handleExpressConfirm}
          />
        </div>
      )}
      <h5>Pay by credit card</h5>
      {!disabled && (
        <div className="mb-3">
          <PaymentElement
            onChange={({ complete }) => setCardFilled(complete)}
            onLoadError={({ error }) => onLoadError?.(error)}
            options={{
              layout: "tabs",
              // Apple Pay and Google Pay are in the Express Checkout Element
              wallets: { applePay: "never", googlePay: "never" },
            }}
          />
        </div>
      )}
      {errorMessage && (
        <div className="error" role="alert">
          {errorMessage}
        </div>
      )}
      <Button
        disabled={!cardFilled || !!blocked}
        spinner={busy}
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
