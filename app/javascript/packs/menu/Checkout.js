import React, { useEffect, useState } from "react";
import _ from "lodash";
import { loadStripe } from "@stripe/stripe-js";
import { Elements } from "@stripe/react-stripe-js";
import axios from "axios";
import * as Sentry from "@sentry/browser";

import Cart from "./Cart";
import Payment from "./Payment";

const stripePromise = loadStripe(gon.stripeApiKey);

export default function Checkout({
  cart,
  cartDescription,
  menu,
  account,
  comments,
  price,
  onCreateOrder,
  onReturn,
}) {
  const [submitting, setSubmitting] = useState(false);
  const [clientSecret, setClientSecret] = useState("");

  // TODO: could re-run useEffect if price changes
  useEffect(() => {
    axios
      .post("/payment_intents", {
        ...account,
        price,
        description: cartDescription,
      })
      .then(({ data }) => {
        console.log("got from server data.clientSecret=", data.clientSecret);
        setClientSecret(data.clientSecret);
      })
      .catch((error) => {
        console.error("Couldn't create payment intent", error.response);
        window.alert(
          `Couldn't create payment intent on server: ${error.message}`
        );
        Sentry.captureException(error);
        onReturn();
      });
  }, []);

  const handleStripeSuccessful = ({ token }) => {
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

  if (clientSecret === "") {
    return null;
  }

  const stripeOptions = {
    clientSecret,
    appearance: { theme: "stripe" },
  };

  return (
    <>
      <Cart {...{ cart, menu }} />
      <h5>Comments & Special Requests</h5>
      <div className="row mt-2 mb-3">
        <div className="col">{comments}</div>
      </div>
      <div className="checkout">
        <Elements stripe={stripePromise} options={stripeOptions}>
          <Payment
            {...{
              email: account.email,
              price,
              clientSecret,
              // onToken: handleStripeSuccessful,
            }}
          />
        </Elements>
      </div>
    </>
  );
}
