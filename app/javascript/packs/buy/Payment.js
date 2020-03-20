import React, { } from 'react';
import {
  injectStripe,
  StripeProvider,
  Elements,
} from 'react-stripe-elements';

import Card from './Card'
import PaymentRequest from './PaymentRequest'

const stripeApiKey = "pk_test_uAmNwPrPVkEoywEZYTE66AnV00mGp7H2Ud";
const WrappedPaymentRequest = injectStripe(PaymentRequest);
const WrappedCard = injectStripe(Card);

export default function Payment({ choice, price }) {
  const handleCardToken = ({token}) => {
    console.log("card token=", token);

    // TODO: send token to rails
  }

  const handlePaymentResultToken = ({ token }) => {
    // with payment request, the price sent to stripe
    console.log("paymentResult token=", token);

    // TODO: send token to rails
  };

  return (
    <>
      <StripeProvider apiKey={stripeApiKey}>
        <Elements>
          <WrappedPaymentRequest
            onToken={handlePaymentResultToken}
            choice={choice}
            price={price}
          />
        </Elements>
      </StripeProvider>
      <br/>
      <StripeProvider apiKey={stripeApiKey}>
        <Elements>
          <WrappedCard onToken={handleCardToken} />
        </Elements>
      </StripeProvider>
    </>
  );
}
