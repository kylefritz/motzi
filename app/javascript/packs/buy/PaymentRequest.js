import React, { useEffect, useState } from "react";
import { PaymentRequestButtonElement } from "react-stripe-elements";

// The Payment Request Button is a single integration that allows you to accept Apple Pay,
// Google Pay, Microsoft Pay, and the Payment Request API.
export default function PaymentRequest({ stripe, onToken, credits, price }) {
  const [paymentRequest, setPaymentRequest] = useState();
  useEffect(() => {
    // For full documentation of the available paymentRequest options, see:
    // https://stripe.com/docs/stripe.js#the-payment-request-object
    const pr = stripe.paymentRequest({
      country: "US",
      currency: "usd",
      total: {
        label: `${credits} credits`,
        amount: price,
      },
      // Requesting the payer’s name, email, or phone is optional, but recommended.
      // It also results in collecting their billing address for Apple Pay.
      requestPayerName: true,
      requestPayerEmail: true,
    });

    pr.canMakePayment().then((result) => {
      console.log("paymentRequest supported?", !!result);
      setCanMakePayment(!!result);
    });

    pr.on("token", ({ complete, token, ...data }) => {
      onToken({ token, data });
      complete("success");
    });

    setPaymentRequest(pr);
  }, []);

  const [canMakePayment, setCanMakePayment] = useState(false);

  if (!canMakePayment) {
    return (
      <div className="d-none">
        Fancy payment button not supported by this browser
      </div>
    );
  }

  // For more details on how to style the Payment Request Button, see:
  // https://stripe.com/docs/elements/payment-request-button#styling-the-element
  return (
    <>
      <PaymentRequestButtonElement
        paymentRequest={paymentRequest}
        className="PaymentRequestButton"
        style={{ paymentRequestButton: { theme: "light", height: "64px" } }}
      />
      <br />
    </>
  );
}
