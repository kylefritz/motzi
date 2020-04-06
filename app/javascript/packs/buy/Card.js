import React, { useState } from "react";
import { CardElement } from "react-stripe-elements";
import { formatMoney } from "accounting";

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

export default function Card({ stripe, onToken, credits, price }) {
  const [errorMessage, setErrorMessage] = useState();
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
    stripe.createToken().then(onToken);
  };

  return (
    <div className="checkout">
      <form onSubmit={handleSubmit}>
        <h5>Pay by credit card</h5>
        <CardElement onChange={handleCardChange} {...createOptions()} />
        {errorMessage && (
          <div className="error" role="alert">
            {errorMessage}
          </div>
        )}
        <button
          disabled={!cardFilled}
          className="btn btn-primary btn-lg btn-block"
          type="submit"
        >
          Charge credit card {formatMoney(price)} for {credits} credits
        </button>
      </form>
    </div>
  );
}
