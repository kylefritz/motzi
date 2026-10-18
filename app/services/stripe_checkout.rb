# Takes a card payment with a Stripe PaymentIntent (#412), for marketplace and
# holiday orders and for credit purchases.
#
# The browser collects the card (or Apple Pay / Google Pay) with the Payment
# Element and Express Checkout Element and sends us a ConfirmationToken. We
# create and confirm the PaymentIntent here, for an amount we computed, so the
# browser never decides what gets charged.
#
# Most cards succeed straight away. A card that needs 3D Secure comes back
# requires_action: we raise RequiresAction, the controller records nothing and
# hands the client secret to the browser, Stripe.js runs the challenge, and the
# browser posts again with the PaymentIntent id. #pay! then checks that intent
# is paid, for this amount, for this purchase.
#
# Either way the purchase is described in the intent's metadata, so the
# payment_intent.succeeded webhook (StripeWebhooksController) can record it
# if the browser never comes back. A unique index on stripe_payment_intent_id
# keeps the two paths from recording it twice.
class StripeCheckout
  KINDS = %w[order credits].freeze

  # Stripe's smallest USD charge
  MINIMUM_CENTS = 50

  # Stripe metadata values are capped at 500 characters
  METADATA_VALUE_LIMIT = 500

  # Shown when Stripe rejects a request outright; nothing was charged.
  FAILED_MESSAGE = "Something went wrong with your payment. Please try again.".freeze

  # A message safe to show the customer
  class PaymentError < StandardError; end

  # The card needs the customer to authenticate (3D Secure) in the browser.
  class RequiresAction < StandardError
    attr_reader :client_secret, :payment_intent_id

    def initialize(payment_intent)
      @client_secret = payment_intent.client_secret
      @payment_intent_id = payment_intent.id
      super("payment #{payment_intent.id} requires action")
    end
  end

  # What gets stored on the Order or CreditItem.
  Payment = Data.define(:payment_intent_id, :charge_id, :receipt_url, :amount) do
    def self.from_intent(intent)
      charge = intent.latest_charge
      charge_id = charge.is_a?(String) ? charge : charge&.id
      new(
        payment_intent_id: intent.id,
        # A paid order is told apart from a credit-spending one by
        # stripe_charge_id (see User#credits), so it must never be blank.
        charge_id: charge_id.presence || intent.id,
        receipt_url: charge.respond_to?(:receipt_url) ? charge.receipt_url : nil,
        amount: BigDecimal(intent.amount) / 100
      )
    end

    def record_attrs
      {
        stripe_payment_intent_id: payment_intent_id,
        stripe_charge_id: charge_id,
        stripe_receipt_url: receipt_url,
        stripe_charge_amount: amount
      }
    end
  end

  # kind: "order" or "credits"
  # amount_cents: what to charge, computed by the server
  # purchase: what is being bought ({ menu_id:, cart: } or { user_id:, credits: }).
  #   It is stored in the metadata and fingerprinted, so a confirmed intent
  #   can only be used for the purchase it was created for.
  # metadata: anything else the webhook needs to record the purchase
  def initialize(kind:, amount_cents:, email:, description:, purchase:, metadata: {})
    raise ArgumentError, "unknown kind #{kind}" unless KINDS.include?(kind)

    @kind = kind
    @amount_cents = amount_cents
    @email = email.to_s.strip.downcase
    @description = description
    @purchase = purchase.transform_keys(&:to_s).transform_values(&:to_s)
    @metadata = metadata.transform_keys(&:to_s)
  end

  # Charges a ConfirmationToken, or verifies a PaymentIntent the browser has
  # finished authenticating. Returns a Payment, or raises RequiresAction,
  # PaymentError or Stripe::CardError.
  def pay!(confirmation_token_id: nil, payment_intent_id: nil)
    if payment_intent_id.present?
      verify!(Stripe::PaymentIntent.retrieve({ id: payment_intent_id, expand: [ "latest_charge" ] }))
    elsif confirmation_token_id.present?
      confirm!(confirmation_token_id)
    else
      raise PaymentError, "Stripe credit card not submitted"
    end
  end

  def digest
    self.class.digest(kind: @kind, amount_cents: @amount_cents, purchase: @purchase)
  end

  def self.digest(kind:, amount_cents:, purchase:)
    canonical = purchase.to_h.transform_keys(&:to_s).transform_values(&:to_s).sort.to_json
    Digest::SHA256.hexdigest([ kind, amount_cents.to_i, canonical ].join("|"))[0, 32]
  end

  # Cart lines as "item_id:pickup_day_id:quantity,..." so a cart fits in
  # Stripe metadata.
  def self.encode_cart(cart_items)
    cart_items.map { |attrs| [ attrs[:item_id], attrs[:pickup_day_id], attrs[:quantity] ].map(&:to_i).join(":") }.join(",")
  end

  def self.decode_cart(encoded)
    encoded.to_s.split(",").map do |line|
      item_id, pickup_day_id, quantity = line.split(":").map(&:to_i)
      { item_id:, pickup_day_id:, quantity: }
    end
  end

  # Joins a value that #metadata split across key, key_2, key_3...
  def self.read_metadata(metadata, key)
    metadata = metadata.to_h.transform_keys(&:to_s)
    [ metadata[key], *(2..).lazy.map { |n| metadata["#{key}_#{n}"] }.take_while(&:present?) ].join
  end

  private

  def confirm!(confirmation_token_id)
    if @amount_cents < MINIMUM_CENTS
      raise PaymentError, "Card payments must be at least $#{format('%.2f', MINIMUM_CENTS / 100.0)}"
    end

    intent = Stripe::PaymentIntent.create(
      {
        amount: @amount_cents,
        currency: "usd",
        confirm: true,
        confirmation_token: confirmation_token_id,
        # Cards, Apple Pay and Google Pay only: none of them redirect away, so
        # no return_url, and 3D Secure runs in place via handleNextAction.
        payment_method_types: [ "card" ],
        receipt_email: @email,
        description: @description.to_s.truncate(1000),
        metadata: metadata,
        expand: [ "latest_charge" ]
      },
      # A retried request (double click, flaky network) must not charge twice.
      # A ConfirmationToken can only be used once, so its id is a natural key.
      { idempotency_key: "motzi-#{@kind}-#{confirmation_token_id}" }
    )

    case intent.status
    when "succeeded" then Payment.from_intent(intent)
    when "requires_action" then raise RequiresAction.new(intent)
    else raise PaymentError, "Your payment didn't go through. Please try another card."
    end
  end

  def verify!(intent)
    intent_metadata = intent.metadata.to_h.transform_keys(&:to_s)
    mismatch =
      if intent.status != "succeeded" then "status #{intent.status}"
      elsif intent_metadata["kind"] != @kind then "kind #{intent_metadata["kind"]}"
      elsif intent.amount != @amount_cents then "amount #{intent.amount} != #{@amount_cents}"
      elsif intent.currency != "usd" then "currency #{intent.currency}"
      elsif intent_metadata["digest"] != digest then "purchase digest"
      elsif intent_metadata["email"].to_s.downcase != @email then "email"
      end

    if mismatch
      Rails.logger.warn "StripeCheckout: payment intent #{intent.id} rejected (#{mismatch})"
      raise PaymentError, "We couldn't confirm your payment. Please try again."
    end

    Payment.from_intent(intent)
  end

  def metadata
    entries = { "kind" => @kind, "digest" => digest, "email" => @email }
    @purchase.each { |key, value| entries["purchase_#{key}"] = value }
    entries.merge!(@metadata.compact.transform_values(&:to_s))

    # Values over Stripe's limit are split across key, key_2, key_3...
    entries.each_with_object({}) do |(key, value), split|
      chunks = value.scan(/.{1,#{METADATA_VALUE_LIMIT}}/m).presence || [ "" ]
      chunks.each_with_index { |chunk, i| split[i.zero? ? key : "#{key}_#{i + 1}"] = chunk }
    end
  end
end
