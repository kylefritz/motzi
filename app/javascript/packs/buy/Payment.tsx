import React, { useEffect, useState } from "react";
import { Elements } from "@stripe/react-stripe-js";
import type { Stripe } from "@stripe/stripe-js";

import Card, { MINIMUM_CARD_PAYMENT, NoCharge, type PayProps } from "./Card";
import {
  loadStripeWithRetry,
  reportStripeLoadFailure,
  trackStripeLoad,
} from "./stripeLoad";

export const LOAD_FAILED_MESSAGE =
  "We couldn't load the card form. Check your connection or turn off any content blocker, then try again.";

type PaymentProps = PayProps & {
  price: number | null;
  stripeApiKey?: string;
};

export default function Payment({
  price,
  stripeApiKey,
  ...cardProps
}: PaymentProps) {
  const [stripe, setStripe] = useState<Stripe | null>(null);
  const [loadFailed, setLoadFailed] = useState(false);
  // Try again presses; a new attempt reloads Stripe.js and remounts Elements
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let current = true;
    loadStripeWithRetry(stripeApiKey || "", attempt).then(
      (loaded) => current && setStripe(loaded),
      (err) => {
        if (!current) return;
        trackStripeLoad("gave_up", { attempt });
        reportStripeLoadFailure("script", err, { attempt });
        setLoadFailed(true);
      }
    );
    return () => {
      current = false;
    };
  }, [stripeApiKey, attempt]);

  // Stripe.js loaded but its card form didn't (Card's onLoadError).
  const handleElementLoadError = (error: unknown) => {
    trackStripeLoad("element_failed", {
      attempt,
      error: (error as Error)?.message,
    });
    reportStripeLoadFailure("element", error, { attempt });
    setLoadFailed(true);
  };

  const tryAgain = () => {
    trackStripeLoad("retry_clicked", { attempt: attempt + 1 });
    setStripe(null);
    setLoadFailed(false);
    setAttempt((n) => n + 1);
  };

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
  if (loadFailed) {
    return (
      <div className="checkout">
        <div className="alert alert-warning" role="alert">
          <p>{LOAD_FAILED_MESSAGE}</p>
          <button
            type="button"
            className="btn btn-outline-primary"
            onClick={tryAgain}
          >
            Try again
          </button>
        </div>
      </div>
    );
  }
  return (
    <div className="checkout">
      <Elements
        // a new attempt starts a fresh Elements group with the new Stripe
        key={attempt}
        stripe={stripe}
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
        <Card
          price={price}
          onLoadError={handleElementLoadError}
          {...cardProps}
        />
      </Elements>
    </div>
  );
}
