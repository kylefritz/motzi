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

export default function Payment({ credits, price, stripeApiKey, onCardToken, onPaymentResult }) {
  return (
    <>
      <StripeProvider apiKey={stripeApiKey}>
        <Elements>
          <WrappedPaymentRequest
            onToken={onPaymentResult}
            credits={credits}
            price={price}
          />
        </Elements>
      </StripeProvider>
      <StripeProvider apiKey={stripeApiKey}>
        <Elements>
          <WrappedCard onToken={onCardToken} price={price} credits={credits} />
        </Elements>
      </StripeProvider>
    </>
  );
}
