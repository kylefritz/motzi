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

export default function Card({
  stripe,
  onToken,
  credits,
  price,
  submitting,
  disabled,
}) {
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
    if (price > 0) {
      stripe.createToken().then(onToken);
    } else {
      onToken({ token: { id: null } });
    }
  };
  const isZeroPrice = price === 0;
  const isNullPrice = price === null;
  if (isZeroPrice) {
    return (
      <div className="checkout">
        <button
          disabled={submitting}
          className="btn btn-primary btn-lg btn-block"
          onClick={handleSubmit}
          type="submit"
        >
          {submitting ? (
            <>
              <span
                className="spinner-border spinner-border-sm mr-2"
                role="status"
                aria-hidden="true"
              />
              Purchasing...
            </>
          ) : (
            "Submit Order"
          )}
        </button>
      </div>
    );
  }
  return (
    <div className="checkout">
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
        <button
          disabled={!cardFilled || submitting || isNullPrice}
          className="btn btn-primary btn-lg btn-block"
          type="submit"
        >
          {submitting ? (
            <>
              <span
                className="spinner-border spinner-border-sm mr-2"
                role="status"
                aria-hidden="true"
              />
              Purchasing...
            </>
          ) : isNullPrice ? (
            "Select an item"
          ) : (
            `Charge credit card ${formatMoney(price)} ${
              credits ? ` for ${credits} credits` : ""
            }`
          )}
        </button>
      </form>
    </div>
  );
}
