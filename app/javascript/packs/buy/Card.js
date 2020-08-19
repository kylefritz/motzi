import React, { useState } from "react";
import { CardElement } from "react-stripe-elements";
import { formatMoney } from "accounting";

export default function Card({
  stripe,
  onToken,
  credits,
  price,
  submitting,
  disabled,
}) {
  const [errorMessage, setErrorMessage] = useState();
  const [waitingOnStripe, setWaitingOnStripe] = useState();
  const [cardFilled, setCardFilled] = useState(false);
  const handleCardChange = ({ error, complete }) => {
    setErrorMessage(error ? error.message : null);
    setCardFilled(complete);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!stripe) {
      console.log("Stripe.js hasn't loaded yet.");
      return;
    }
    if (price > 0) {
      setWaitingOnStripe(true);
      stripe.createToken().then((token) => {
        onToken(token);
        setWaitingOnStripe(false);
      });
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

function Button({ disabled, onClick, spinner, text }) {
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
