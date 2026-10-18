import React, { useMemo } from "react";
import { Elements } from "@stripe/react-stripe-js";
import { loadStripe } from "@stripe/stripe-js";

import Card, { NoCharge, type PayProps } from "./Card";

type PaymentProps = PayProps & {
  price: number | null;
  stripeApiKey?: string;
};

// Smallest amount Elements will take; Card won't pay less than Stripe's
// minimum, so this only stands in while the cart is empty or the price is
// still being typed.
const MIN_ELEMENTS_AMOUNT_CENTS = 50;

export default function Payment({
  price,
  stripeApiKey,
  ...cardProps
}: PaymentProps) {
  const stripePromise = useMemo(
    () => loadStripe(stripeApiKey || ""),
    [stripeApiKey]
  );

  // A $0 pay-what-you-can order has nothing to charge, so no Stripe Elements.
  if (price === 0) {
    return (
      <div className="checkout">
        <NoCharge {...cardProps} />
      </div>
    );
  }

  // Deferred intent: the Payment and Express Checkout Elements collect the
  // card or wallet for this amount (kept current as the price or tip
  // changes), and the server creates the PaymentIntent (StripeCheckout).
  // Card only, which covers Apple Pay and Google Pay, so nothing redirects.
  const amount = Math.max(
    Math.round((price ?? 0) * 100),
    MIN_ELEMENTS_AMOUNT_CENTS
  );
  return (
    <div className="checkout">
      <Elements
        stripe={stripePromise}
        options={{
          mode: "payment",
          amount,
          currency: "usd",
          paymentMethodTypes: ["card"],
        }}
      >
        <Card price={price} {...cardProps} />
      </Elements>
    </div>
  );
}
