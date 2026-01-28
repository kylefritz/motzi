import React from "react";
import { injectStripe, StripeProvider, Elements } from "react-stripe-elements";

import Card from "./Card";
const WrappedCard = injectStripe(Card);

// we need to use a class style component here so we can
// call the onCardToken prop from a test
export default class Payment extends React.Component {
  render() {
    const {
      credits,
      price,
      stripeApiKey,
      onCardToken,
      onPaymentResult,
      submitting,
      disabled,
    } = this.props;
    return (
      <div className="checkout">
        <StripeProvider apiKey={stripeApiKey}>
          <Elements>
            <WrappedCard
              {...{
                price,
                credits,
                submitting,
                onToken: onCardToken,
                disabled,
              }}
            />
          </Elements>
        </StripeProvider>
      </div>
    );
  }
}
