import React, { useState } from "react";
import { CardElement, useElements, useStripe } from "@stripe/react-stripe-js";
import { formatMoney } from "accounting";

type CardProps = {
  onToken: (payload: { token: { id: string | null } }) => void;
  credits?: number;
  price: number | null;
  submitting: boolean;
  disabled?: boolean;
};

export default function Card({
  onToken,
  credits,
  price,
  submitting,
  disabled,
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

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (price > 0 && (!stripe || !elements)) {
      console.log("Stripe.js hasn't loaded yet.");
      return;
    }
    if (price > 0) {
      setWaitingOnStripe(true);
      const cardElement = elements.getElement(CardElement);
      if (!cardElement) {
        setWaitingOnStripe(false);
        return;
      }
      const { token, error } = await stripe.createToken(cardElement);
      if (error) {
        setErrorMessage(error.message);
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
      <Button spinner={submitting} text="Submit Order" onClick={handleSubmit} />
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
        disabled={!cardFilled || isNullPrice}
        spinner={submitting || waitingOnStripe}
        text={
          isNullPrice
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
