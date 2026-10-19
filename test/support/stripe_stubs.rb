require "webmock/minitest"

# WebMock stubs for the Stripe calls the app makes: creating and confirming a
# PaymentIntent (POST /v1/payment_intents), reading one back
# (GET /v1/payment_intents/:id) and naming its order on it
# (POST /v1/payment_intents/:id), plus signed webhook payloads.
#
# This replaced stripe-ruby-mock, which capped the stripe gem at < 14 and
# lagged the real API. Stubbing at the HTTP layer exercises the real stripe
# gem (request encoding, response parsing, error mapping) against responses
# shaped like Stripe's documented ones. VCR is hooked into WebMock, but it
# hands explicitly stubbed requests to WebMock rather than raising.
module StripeStubs
  STRIPE_PAYMENT_INTENTS_URL = "https://api.stripe.com/v1/payment_intents".freeze
  JSON_HEADERS = { "Content-Type" => "application/json" }.freeze
  WEBHOOK_SECRET = "whsec_test_stubbed".freeze

  # The stripe gem refuses to build a request without a key. Nothing reaches
  # Stripe (WebMock blocks real connections), so any test-shaped key will do.
  # Always this one, never a key from .env, so a real key can't show up in a
  # WebMock failure message.
  Stripe.api_key = "sk_test_stubbed_by_webmock"

  # Forget stubs and the request log between tests so assert_requested only
  # sees the current test. (webmock/minitest does this via a `teardown`
  # method alias, which a test class's own `def teardown` silently replaces.)
  def self.included(base)
    base.teardown { WebMock.reset! }
  end

  # What stripe.createConfirmationToken hands the browser; the server passes
  # it to Stripe when it creates the PaymentIntent.
  def stripe_confirmation_token
    "ctoken_test_visa"
  end

  # Creating (and confirming) a PaymentIntent. Echoes back the amount,
  # description and metadata that were posted so assertions can check what the
  # app sent; the last one is kept in #created_payment_intent so a test can
  # finish a 3D Secure payment with #stub_payment_intent_retrieve.
  # Each request gets a new intent id unless `id` is given.
  def stub_payment_intent_create(status: "succeeded", id: nil)
    stub_payment_intent_update
    stub_request(:post, STRIPE_PAYMENT_INTENTS_URL).to_return do |request|
      posted = Rack::Utils.parse_nested_query(request.body)
      @created_payment_intent = payment_intent_json(
        id: id || "pi_test_#{SecureRandom.hex(8)}", status: status, amount: posted["amount"].to_i, metadata: posted["metadata"] || {},
        description: posted["description"], receipt_email: posted["receipt_email"]
      )
      { status: 200, headers: JSON_HEADERS, body: @created_payment_intent.to_json }
    end
  end

  def created_payment_intent
    @created_payment_intent or raise "no PaymentIntent was created"
  end

  # Reading a PaymentIntent back, by default the one the app just created,
  # now paid (the customer finished 3D Secure).
  def stub_payment_intent_retrieve(intent = created_payment_intent, status: "succeeded", **overrides)
    intent = intent.merge(payment_intent_json(**intent.slice(:id, :amount, :metadata), status: status)).merge(overrides)
    stub_payment_intent_update
    stub_request(:get, %r{\A#{STRIPE_PAYMENT_INTENTS_URL}/#{intent[:id]}(\?|\z)})
      .to_return(status: 200, headers: JSON_HEADERS, body: intent.to_json)
    intent
  end

  # Updating a PaymentIntent (LinkStripePaymentJob naming its order or credit
  # item). Echoes back the description and metadata that were posted. The
  # create and retrieve stubs set this up too, since every paid intent that
  # gets recorded is then updated.
  def stub_payment_intent_update(id = %r{[^/?]+})
    stub_request(:post, %r{\A#{STRIPE_PAYMENT_INTENTS_URL}/#{id}\z}).to_return do |request|
      posted = Rack::Utils.parse_nested_query(request.body)
      intent_id = request.uri.path.split("/").last
      body = payment_intent_json(id: intent_id, status: "succeeded", amount: 1000, metadata: posted["metadata"] || {},
                                 description: posted["description"])
      { status: 200, headers: JSON_HEADERS, body: body.to_json }
    end
  end

  def payment_intent_json(id:, status:, amount:, metadata:, description: nil, receipt_email: nil)
    paid = status == "succeeded"
    {
      id: id,
      object: "payment_intent",
      status: status,
      amount: amount,
      currency: "usd",
      client_secret: "#{id}_secret_test",
      description: description,
      receipt_email: receipt_email,
      metadata: metadata,
      latest_charge: paid ? charge_json(id: "ch_test_#{id.delete_prefix('pi_test_')}", amount: amount) : nil,
      next_action: status == "requires_action" ? { type: "use_stripe_sdk" } : nil
    }
  end

  def charge_json(id:, amount:)
    {
      id: id,
      object: "charge",
      status: "succeeded",
      paid: true,
      amount: amount,
      currency: "usd",
      receipt_url: "https://pay.stripe.com/receipts/test_receipt"
    }
  end

  # A declined card, shaped like Stripe's real 402 so the stripe gem raises
  # Stripe::CardError with error.code / decline_code populated the way the
  # controllers log them.
  def stub_stripe_card_declined(message: "Your card was declined.", decline_code: "generic_decline")
    stub_request(:post, STRIPE_PAYMENT_INTENTS_URL).to_return(
      status: 402,
      headers: JSON_HEADERS,
      body: {
        error: {
          type: "card_error",
          code: "card_declined",
          decline_code: decline_code,
          message: message,
          payment_intent: { id: "pi_declined_test", object: "payment_intent", status: "requires_payment_method" },
          param: nil
        }
      }.to_json
    )
  end

  # Stripe rejecting the request itself (nothing is charged): an
  # invalid_request_error (e.g. an expired or already used ConfirmationToken)
  # or an idempotency_error (the same key reused with different parameters).
  def stub_stripe_request_rejected(type: "invalid_request_error", method: :post, url: STRIPE_PAYMENT_INTENTS_URL)
    stub_request(method, url).to_return(
      status: 400,
      headers: JSON_HEADERS,
      body: {
        error: {
          type: type,
          code: type == "invalid_request_error" ? "resource_missing" : nil,
          message: "Stripe rejected the request (#{type})"
        }
      }.to_json
    )
  end

  # A payment_intent.succeeded event and the Stripe-Signature header Stripe
  # would send with it.
  def signed_stripe_event(intent, type: "payment_intent.succeeded", secret: WEBHOOK_SECRET)
    payload = { id: "evt_test_#{SecureRandom.hex(6)}", object: "event", type: type, data: { object: intent } }.to_json
    timestamp = Time.now.to_i
    signature = Stripe::Webhook::Signature.compute_signature(Time.at(timestamp), payload, secret)
    [ payload, "t=#{timestamp},v1=#{signature}" ]
  end
end
