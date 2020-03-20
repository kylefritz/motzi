import React, { } from 'react';
import {
  injectStripe,
  StripeProvider,
  Elements,
} from 'react-stripe-elements';

import Card from './Card'
import PaymentRequest from './PaymentRequest'

const WrappedPaymentRequest = injectStripe(PaymentRequest);
const WrappedCard = injectStripe(Card);

export default function Payment({ choice, price, stripeApiKey, onCardToken, onPaymentResult }) {
  return (
    <>
      <StripeProvider apiKey={stripeApiKey}>
        <Elements>
          <WrappedPaymentRequest
            onToken={onPaymentResult}
            choice={choice}
            price={price}
          />
        </Elements>
      </StripeProvider>
      <br />
      <StripeProvider apiKey={stripeApiKey}>
        <Elements>
          <WrappedCard onToken={onCardToken} />
        </Elements>
      </StripeProvider>
    </>
  );
}
