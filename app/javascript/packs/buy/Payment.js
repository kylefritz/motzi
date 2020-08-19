import React from "react";
import { injectStripe, StripeProvider, Elements } from "react-stripe-elements";

import Card from "./Card";
const WrappedCard = injectStripe(Card);

import PaymentRequest from "./PaymentRequest";
const WrappedPaymentRequest = injectStripe(PaymentRequest);

// we need to use a class style component here so we can
// call the onToken prop from a test
export default class Payment extends React.Component {
  render() {
    const {
      credits,
      price,
      stripeApiKey,
      onToken,
      submitting,
      disabled,
    } = this.props;
    return (
      <StripeProvider apiKey={stripeApiKey}>
        <div className="checkout">
          <Elements>
            <WrappedPaymentRequest onToken credits={credits} price={price} />
          </Elements>
          <Elements>
            <WrappedCard
              {...{
                price,
                credits,
                submitting,
                onToken,
                disabled,
              }}
            />
          </Elements>
        </div>
      </StripeProvider>
    );
  }
}
