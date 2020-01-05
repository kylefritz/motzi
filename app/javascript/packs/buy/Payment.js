import React, { } from 'react';
import {
  injectStripe,
  StripeProvider,
  Elements,
} from 'react-stripe-elements';

import Card from './Card'
import PaymentRequest from './PaymentRequest'

export default function Payment({ choice, price }) {
  const WrappedPaymentRequest = injectStripe(PaymentRequest);
  const WrappedCard = injectStripe(Card);

  const handleResult = function () {

  }

  return <>
    <StripeProvider apiKey="pk_test_uAmNwPrPVkEoywEZYTE66AnV00mGp7H2Ud">
      <Elements>
        <WrappedCard handleResult={handleResult} choice={choice} price={price} />
      </Elements>
    </StripeProvider>
    <br />
    <StripeProvider apiKey="pk_test_uAmNwPrPVkEoywEZYTE66AnV00mGp7H2Ud">
      <Elements>
        <WrappedPaymentRequest handleResult={handleResult} choice={choice} price={price} />
      </Elements>
    </StripeProvider>
  </>
}
