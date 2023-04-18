import React, { useEffect, useState } from "react";
import _ from "lodash";
import { loadStripe } from "@stripe/stripe-js";
import { Elements } from "@stripe/react-stripe-js";
import axios from "axios";

import Cart from "./Cart";
import CheckoutForm from "./CheckoutForm";

const stripePromise = loadStripe(gon.stripeApiKey);

export default function Checkout({
  cart,
  menu,
  account,
  comments,
  price,
  onCreateOrder,
}) {
  const [submitting, setSubmitting] = useState(false);
  const [clientSecret, setClientSecret] = useState("");

  // TODO: could re-run useEffect if price changes
  useEffect(() => {
    axios
      .post("/payment_intents", {})
      .then(({ data }) => {
        console.log("got from server data.clientSecret=", data.clientSecret);
        setClientSecret(data.clientSecret);
      })
      .catch((error) => {
        console.error("Couldn't create payment intent", error.response);
        window.alert(`Couldn't create payment: ${error.message}`);
        Sentry.captureException(err);
      });
  }, []);

  const handleCardToken = ({ token }) => {
    console.log("handleCardToken", { token, price: totalPrice });
    setSubmitting(true);

    // send stripe token to rails to complete purchase
    onCreateOrder({
      ...account,
      comments,
      cart,
      price,
      token: token.id,
    }).then(() => setSubmitting(false));
  };

  const appearance = {
    theme: "stripe",
  };
  const options = {
    clientSecret,
    appearance,
  };

  return (
    <>
      <Cart {...{ cart, menu }} />
      <h5>Comments & Special Requests</h5>
      <div className="row mt-2 mb-3">
        <div className="col">{comments}</div>
      </div>
      (clientSecret !== "" && (
      <div className="checkout">
        <Elements stripe={stripePromise} options={options}>
          <CheckoutForm
            {...{
              price,
              clientSecret,
              onToken: handleCardToken,
            }}
          />
        </Elements>
      </div>
      ))
    </>
  );
}
