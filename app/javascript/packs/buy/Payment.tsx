import React, { useMemo } from "react";
import { Elements } from "@stripe/react-stripe-js";
import { loadStripe } from "@stripe/stripe-js";

import Card from "./Card";

type PaymentProps = {
  credits?: number;
  price: number | null;
  stripeApiKey?: string;
  onCardToken: (payload: { token: { id: string | null } }) => void;
  submitting: boolean;
  disabled?: boolean;
};

export default function Payment({
  credits,
  price,
  stripeApiKey,
  onCardToken,
  submitting,
  disabled,
}: PaymentProps) {
  const stripePromise = useMemo(
    () => loadStripe(stripeApiKey || ""),
    [stripeApiKey]
  );

  return (
    <div className="checkout">
      <Elements stripe={stripePromise}>
        <Card
          {...{
            price,
            credits,
            submitting,
            onToken: onCardToken,
            disabled,
          }}
        />
      </Elements>
    </div>
  );
}
