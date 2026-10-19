# Stripe's payment_intent.succeeded webhook (#412). The browser normally
# records a payment as soon as it succeeds; this places the order (or adds
# the credits) when it doesn't, e.g. a customer who closes the tab during
# 3D Secure. StripeCheckout::Fulfillment makes recording it twice a no-op.
#
# The endpoint and its signing secret (STRIPE_WEBHOOK_SECRET) are set up in
# the Stripe dashboard.
class StripeWebhooksController < ActionController::API
  def create
    # Without a secret anyone could sign an event (an empty key is still a key)
    secret = ENV["STRIPE_WEBHOOK_SECRET"].presence
    unless secret
      logger.error "stripe webhook rejected: STRIPE_WEBHOOK_SECRET is not set"
      return head :bad_request
    end

    event = Stripe::Webhook.construct_event(request.raw_post, request.headers["Stripe-Signature"].to_s, secret)

    if event.type == "payment_intent.succeeded"
      intent_id = event.data.object.id
      if StripeCheckout::Fulfillment.recorded?(intent_id)
        logger.info "stripe webhook #{event.id}: payment #{intent_id} already recorded"
      else
        # Only the event type and the intent id are read from the event, so
        # the endpoint's API version doesn't matter: the intent is re-read at
        # the gem's version, with the charge (and its receipt) expanded.
        intent = Stripe::PaymentIntent.retrieve({ id: intent_id, expand: [ "latest_charge" ] })
        record = StripeCheckout::Fulfillment.record!(intent)
        logger.info "stripe webhook #{event.id}: payment #{intent.id} is #{record ? "#{record.class.name} #{record.id}" : "not recorded (not ours, or refunded)"}"
      end
    end

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    logger.warn "stripe webhook rejected: #{e.message}"
    head :bad_request
  end
end
