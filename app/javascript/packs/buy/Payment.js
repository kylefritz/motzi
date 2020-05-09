import React from "react";
import { injectStripe, StripeProvider, Elements } from "react-stripe-elements";

import Card from "./Card";
const WrappedCard = injectStripe(Card);

/*
import PaymentRequest from "./PaymentRequest";
const WrappedPaymentRequest = injectStripe(PaymentRequest);
<StripeProvider apiKey={stripeApiKey}>
  <Elements>
    <WrappedPaymentRequest
      onToken={onPaymentResult}
      credits={credits}
      price={price}
    />
  </Elements>
</StripeProvider>;
*/

export default function Payment({
  credits,
  price,
  stripeApiKey,
  onCardToken,
  onPaymentResult,
  submitting,
}) {
  return (
    <>
      <StripeProvider apiKey={stripeApiKey}>
        <Elements>
          <WrappedCard
            {...{ price, credits, submitting, onToken: onCardToken }}
          />
        </Elements>
      </StripeProvider>
    </>
  );
}
