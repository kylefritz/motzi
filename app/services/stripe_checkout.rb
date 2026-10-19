# Takes a card payment with a Stripe PaymentIntent (#412), for marketplace and
# holiday orders and for credit purchases.
#
# The browser collects the card (or Apple Pay / Google Pay) with the Payment
# Element and Express Checkout Element and sends us a ConfirmationToken. We
# create and confirm the PaymentIntent here, for an amount the server computed
# and bounds-checked; the amount the browser hands Elements is only what the
# card form and wallet sheet display.
#
# Most cards succeed straight away. A card that needs 3D Secure comes back
# requires_action: we raise RequiresAction, the controller records nothing and
# hands the client secret to the browser, Stripe.js runs the challenge, and the
# browser posts again with the PaymentIntent id. By then the money has moved,
# so that second post doesn't re-run the checkout: .paid_intent! checks the
# intent is ours, paid, not refunded and the requester's, and
# Fulfillment.record! records the purchase its metadata describes.
#
# The purchase is described in the intent's metadata either way, so the
# payment_intent.succeeded webhook (StripeWebhooksController) can record it
# if the browser never comes back. A unique index on stripe_payment_intent_id
# keeps the two paths from recording it twice.
class StripeCheckout
  KINDS = %w[order credits].freeze

  # Stripe's smallest USD charge
  MINIMUM_CENTS = 50

  # Stripe allows 50 metadata keys of up to 500 characters each
  METADATA_VALUE_LIMIT = 500
  METADATA_KEY_LIMIT = 50

  # Shown when Stripe rejects a request outright; nothing was charged.
  FAILED_MESSAGE = "Something went wrong with your payment. Please try again.".freeze
  # Shown when the payment hasn't settled yet; the webhook records it once it has.
  PENDING_MESSAGE = "Your payment is processing. We'll email your confirmation as soon as it goes through.".freeze
  REJECTED_MESSAGE = "We couldn't confirm your payment. Please try again.".freeze

  # A message safe to show the customer
  class PaymentError < StandardError; end

  # The payment is still processing; nothing is recorded until it succeeds.
  class Pending < StandardError
    def initialize(msg = PENDING_MESSAGE) = super
  end

  # The card needs the customer to authenticate (3D Secure) in the browser.
  class RequiresAction < StandardError
    attr_reader :client_secret

    def initialize(payment_intent)
      @client_secret = payment_intent.client_secret
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

    # A $0 pay-what-you-can order: no charge, but still a marketplace order.
    def self.free
      new(payment_intent_id: nil, charge_id: nil, receipt_url: nil, amount: BigDecimal("0"))
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

  # Dollars (a param, possibly blank or junk) as whole cents, rounded the same
  # way OrderPricing compares against the minimum.
  def self.to_cents(amount)
    (BigDecimal(amount.to_s, exception: false) || BigDecimal("0")).mult(100, 0).round.to_i
  end

  # kind: "order" or "credits"
  # amount_cents: what to charge, computed by the server
  # purchase: what is being bought ({ menu_id:, cart: } or { user_id:, credits: }),
  #   stored in the metadata as purchase_*
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

  # Creates and confirms the PaymentIntent for a ConfirmationToken. Returns a
  # Payment, or raises RequiresAction, Pending, PaymentError or
  # Stripe::CardError.
  def charge!(confirmation_token_id)
    raise PaymentError, "Stripe credit card not submitted" if confirmation_token_id.blank?
    if @amount_cents < MINIMUM_CENTS
      raise PaymentError, "Card payments must be at least $#{format('%.2f', MINIMUM_CENTS / 100.0)}"
    end
    if metadata.size > METADATA_KEY_LIMIT
      raise PaymentError, "This order is too large to pay for online. Please get in touch and we'll sort it out."
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
    when "processing" then raise Pending
    else raise PaymentError, "Your payment didn't go through. Please try another card."
    end
  end

  # The PaymentIntent the browser posts back after 3D Secure, if it is a
  # paid, unrefunded `kind` intent and the block accepts its metadata as the
  # requester's. Raises Pending while it's still processing, PaymentError
  # otherwise.
  def self.paid_intent!(payment_intent_id, kind:)
    intent = Stripe::PaymentIntent.retrieve({ id: payment_intent_id.to_s, expand: [ "latest_charge" ] })
    metadata = intent.metadata.to_h.transform_keys(&:to_s)
    problem =
      if metadata["kind"] != kind then "kind #{metadata['kind'].inspect}"
      elsif !yield(metadata) then "requester"
      elsif intent.status == "processing" then raise Pending
      elsif intent.status != "succeeded" then "status #{intent.status}"
      elsif refunded?(intent) then "refunded"
      end
    return intent unless problem

    Rails.logger.warn "StripeCheckout: payment intent #{intent.id} rejected (#{problem})"
    raise PaymentError, REJECTED_MESSAGE
  end

  # A refunded payment mustn't be recorded (again) as a purchase.
  def self.refunded?(intent)
    charge = intent.latest_charge
    return false unless charge.respond_to?(:refunded)

    charge.refunded || charge.amount_refunded.to_i.positive?
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
    [ metadata[key], *(2..).lazy.map { |n| metadata["#{key}_#{n}"] }.take_while { |chunk| !chunk.nil? } ].join
  end

  private

  def metadata
    @split_metadata ||= begin
      entries = { "kind" => @kind, "email" => @email }
      @purchase.each { |key, value| entries["purchase_#{key}"] = value }
      entries.merge!(@metadata.compact.transform_values(&:to_s))

      # Values over Stripe's limit are split across key, key_2, key_3...
      entries.each_with_object({}) do |(key, value), split|
        chunks = value.scan(/.{1,#{METADATA_VALUE_LIMIT}}/m).presence || [ "" ]
        chunks.each_with_index { |chunk, i| split[i.zero? ? key : "#{key}_#{i + 1}"] = chunk }
      end
    end
  end
end
