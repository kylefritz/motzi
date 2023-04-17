import React, { useState } from "react";
import { loadStripe } from "@stripe/stripe-js";
import { Elements } from "@stripe/react-stripe-js";
import axios from "axios";
import Card from "./Card";
import accounting from "accounting";
import _ from "lodash";

const stripePromise = loadStripe(gon.stripeApiKey);

// const WrappedCard = injectStripe(Card);

// TODO: this whole file should get deleted

// we need to use a class style component here so we can
// call the onCardToken prop from a test
export default function Payment({
  account,
  description,
  price,
  onCardToken,
  submitting,
  disabled,
}) {
  const [clientSecret, setClientSecret] = useState("");

  // TODO: lock in price
  //
  // create PaymentIntent as soon as the page loads
  const handleStartCheckout = () => {
    axios
      .post("/payment_intents", {
        ...account,
        price,
        description,
      })
      .then(({ data }) => {
        console.log("got from server data.clientSecret=", data.clientSecret);
        setClientSecret(data.clientSecret);
      })
      .catch((error) => {
        console.error("Couldn't create payment intent", error.response);
        window.alert(`Couldn't create payment: ${error.message}`);
        Sentry.captureException(err);
      });
  };

  const appearance = {
    theme: "stripe",
  };
  const options = {
    clientSecret,
    appearance,
  };

  if (clientSecret === "") {
    const text =
      price === null
        ? "Choose an item"
        : `Checkout for ${accounting.formatMoney(price || 0)}`;
    return (
      <div className="checkout">
        <Button text={text} disabled={disabled} onClick={handleStartCheckout} />
      </div>
    );
  }

  return (
    <div className="checkout">
      <Elements stripe={stripePromise}>
        <Card
          {...{
            price,
            submitting,
            onToken: onCardToken,
            disabled,
          }}
        />
      </Elements>
    </div>
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
