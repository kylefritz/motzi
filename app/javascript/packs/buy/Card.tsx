import React, { useState } from "react";
import { CardElement, useElements, useStripe } from "@stripe/react-stripe-js";
import { formatMoney } from "accounting";

// A zero-price order skips Stripe and submits with a null token id.
export type StripeTokenPayload = { token: { id: string | null } };

type CardProps = {
  onToken: (payload: StripeTokenPayload) => void;
  credits?: number;
  price: number | null;
  submitting: boolean;
  disabled?: boolean;
  // when set, the order can't be paid as is (e.g. below its minimum); shown
  // on the disabled pay button
  blockedText?: string | null;
};

export default function Card({
  onToken,
  credits,
  price,
  submitting,
  disabled,
  blockedText,
}: CardProps) {
  const stripe = useStripe();
  const elements = useElements();
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [waitingOnStripe, setWaitingOnStripe] = useState(false);
  const [cardFilled, setCardFilled] = useState(false);
  const handleCardChange = ({
    error,
    complete,
  }: {
    error?: { message: string };
    complete: boolean;
  }) => {
    setErrorMessage(error ? error.message : null);
    setCardFilled(complete);
  };

  const handleSubmit = async (e: React.SyntheticEvent) => {
    e.preventDefault();
    if (blockedText) {
      return;
    }
    const isCharge = price !== null && price > 0;
    if (isCharge && (!stripe || !elements)) {
      console.log("Stripe.js hasn't loaded yet.");
      return;
    }
    if (isCharge && stripe && elements) {
      setWaitingOnStripe(true);
      const cardElement = elements.getElement(CardElement);
      if (!cardElement) {
        setWaitingOnStripe(false);
        return;
      }
      const { token, error } = await stripe.createToken(cardElement);
      if (error) {
        setErrorMessage(error.message ?? null);
        setWaitingOnStripe(false);
        return;
      }
      onToken({ token });
      setWaitingOnStripe(false);
    } else {
      onToken({ token: { id: null } });
    }
  };
  const isZeroPrice = price === 0;
  const isNullPrice = price === null;
  if (isZeroPrice) {
    return (
      <Button
        disabled={!!blockedText}
        spinner={submitting}
        text={blockedText || "Submit Order"}
        onClick={handleSubmit}
      />
    );
  }
  return (
    <form onSubmit={handleSubmit}>
      <h5>Pay by credit card</h5>
      {!disabled && (
        <CardElement onChange={handleCardChange} {...createOptions()} />
      )}
      {errorMessage && (
        <div className="error" role="alert">
          {errorMessage}
        </div>
      )}
      <Button
        disabled={!cardFilled || isNullPrice || !!blockedText}
        spinner={submitting || waitingOnStripe}
        text={
          blockedText
            ? blockedText
            : isNullPrice
              ? "Select an item"
              : [
                  `Charge credit card ${formatMoney(price)}`,
                  credits ? ` for ${credits} credits` : "",
                ].join("")
        }
      />
    </form>
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

// You can customize your Elements to give it the look and feel of your site.
const createOptions = () => {
  return {
    style: {
      base: {
        fontSize: "16px",
        color: "#424770",
        fontFamily: "Open Sans, sans-serif",
        letterSpacing: "0.025em",
        "::placeholder": {
          color: "#aab7c4",
        },
      },
      invalid: {
        color: "#c23d4b",
      },
    },
  };
};
