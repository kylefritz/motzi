require "webmock/minitest"

# WebMock stubs for the only Stripe call the app makes: POST /v1/charges.
#
# This replaced stripe-ruby-mock, which capped the stripe gem at < 14 and
# lagged the real API. Stubbing at the HTTP layer exercises the real stripe
# gem (request encoding, response parsing, error mapping) against responses
# shaped like Stripe's documented ones. VCR is hooked into WebMock, but it
# hands explicitly stubbed requests to WebMock rather than raising.
module StripeStubs
  STRIPE_CHARGES_URL = "https://api.stripe.com/v1/charges".freeze
  JSON_HEADERS = { "Content-Type" => "application/json" }.freeze

  # The stripe gem refuses to build a request without a key. Nothing reaches
  # Stripe (WebMock blocks real connections), so any test-shaped key will do.
  Stripe.api_key = "sk_test_stubbed_by_webmock" if Stripe.api_key.blank?

  # Forget stubs and the request log between tests so assert_requested only
  # sees the current test. (webmock/minitest does this via a `teardown`
  # method alias, which a test class's own `def teardown` silently replaces.)
  def self.included(base)
    base.teardown { WebMock.reset! }
  end

  # What Stripe.js hands the browser; the server only passes it through to
  # Stripe::Charge.create as `source`.
  def stripe_test_token
    "tok_visa"
  end

  # A successful charge. Echoes back the amount, currency, description and
  # metadata that were posted so assertions can check what the app sent.
  def stub_stripe_charge(id: "ch_test_#{SecureRandom.hex(8)}",
                         receipt_url: "https://pay.stripe.com/receipts/test_receipt")
    stub_request(:post, STRIPE_CHARGES_URL).to_return do |request|
      posted = Rack::Utils.parse_nested_query(request.body)
      {
        status: 200,
        headers: JSON_HEADERS,
        body: {
          id: id,
          object: "charge",
          status: "succeeded",
          paid: true,
          captured: true,
          amount: posted["amount"].to_i,
          currency: posted["currency"] || "usd",
          description: posted["description"],
          receipt_email: posted["receipt_email"],
          receipt_url: receipt_url,
          metadata: posted["metadata"] || {}
        }.to_json
      }
    end
  end

  # A declined card, shaped like Stripe's real 402 so the stripe gem raises
  # Stripe::CardError with error.code / decline_code / charge populated the
  # way the controllers log them.
  def stub_stripe_card_declined(message: "Your card was declined.", decline_code: "generic_decline")
    stub_request(:post, STRIPE_CHARGES_URL).to_return(
      status: 402,
      headers: JSON_HEADERS,
      body: {
        error: {
          type: "card_error",
          code: "card_declined",
          decline_code: decline_code,
          message: message,
          charge: "ch_declined_test",
          param: nil
        }
      }.to_json
    )
  end
end
