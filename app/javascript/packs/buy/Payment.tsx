import React, { useMemo } from "react";
import { Elements } from "@stripe/react-stripe-js";
import { loadStripe } from "@stripe/stripe-js";

import Card, { MINIMUM_CARD_PAYMENT, NoCharge, type PayProps } from "./Card";

type PaymentProps = PayProps & {
  price: number | null;
  stripeApiKey?: string;
};

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
  // Elements needs a positive whole number of cents. Card won't pay outside
  // [minPrice, maxPrice], so clamping only matters while the cart is empty or
  // the price is being typed (cleared, the price is NaN).
  const min = Math.max(cardProps.minPrice ?? 0, MINIMUM_CARD_PAYMENT);
  const shown =
    price !== null && Number.isFinite(price)
      ? Math.min(Math.max(price, min), cardProps.maxPrice ?? Infinity)
      : min;
  const amount = Math.round(shown * 100);
  return (
    <div className="checkout">
      <Elements
        stripe={stripePromise}
        options={{
          mode: "payment",
          amount,
          currency: "usd",
          paymentMethodTypes: ["card"],
          // Stripe draws the fields in its own iframes, so they're styled
          // here rather than in our CSS (Motzi purple, ink text, small radii)
          appearance: {
            variables: {
              colorPrimary: "#352C63",
              colorText: "#2E2927",
              borderRadius: "4px",
            },
          },
        }}
      >
        <Card price={price} {...cardProps} />
      </Elements>
    </div>
  );
}
