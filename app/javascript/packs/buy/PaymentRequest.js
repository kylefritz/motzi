import React, { useState } from 'react'
import { PaymentRequestButtonElement } from 'react-stripe-elements'

// The Payment Request Button is a single integration that allows you to accept Apple Pay,
// Google Pay, Microsoft Pay, and the Payment Request API.
export default function PaymentRequest({ stripe, onToken, choice, price }) {
  const [paymentRequest, setPaymentRequest] = useState(() => {
    // For full documentation of the available paymentRequest options, see:
    // https://stripe.com/docs/stripe.js#the-payment-request-object
    return stripe.paymentRequest({
      country: 'US',
      currency: 'usd',
      total: {
        label: choice,
        amount: price,
      },
      // Requesting the payer’s name, email, or phone is optional, but recommended.
      // It also results in collecting their billing address for Apple Pay.
      requestPayerName: true,
      requestPayerEmail: true,
    })
  })
  const [canMakePayment, setCanMakePayment] = useState(false)

  paymentRequest.on('token', ({ complete, token, ...data }) => {
    onToken({ token, data })
    complete('success')
  })

  paymentRequest.canMakePayment().then(result => {
    console.log("paymentRequest supported?", !!result);
    setCanMakePayment(!!result)
  })

  if (!canMakePayment) {
    return (
      <div className="d-none">
        Fancy payment button not supported by this browser
      </div>
    );
  }

  // For more details on how to style the Payment Request Button, see:
  // https://stripe.com/docs/elements/payment-request-button#styling-the-element
  return <PaymentRequestButtonElement
    paymentRequest={this.state.paymentRequest}
    className="PaymentRequestButton"
    style={{ paymentRequestButton: { theme: 'light', height: '64px' } }}
  />
}
