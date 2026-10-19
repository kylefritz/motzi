# Points a PaymentIntent at the Order or CreditItem it paid for (#427), so a
# payment found in the Stripe dashboard (refunds, disputes) leads back to
# Motzi. The intent is created before the record exists (#412), so its
# description and metadata can only name the record once it's committed.
#
# Enqueued by StripeCheckout::Fulfillment after the record commits. Setting
# the same description and metadata again changes nothing, so a retry is
# harmless, and a failure is reported rather than raised: the link is a
# convenience and never affects the purchase.
class LinkStripePaymentJob < ApplicationJob
  queue_as :default

  # Stripe being briefly unreachable, rate limiting or erroring on its side
  TRANSIENT_ERRORS = [ Stripe::APIConnectionError, Stripe::RateLimitError, Stripe::APIError ].freeze

  # Handlers declared later win, so transient errors are retried and anything
  # else from Stripe (say an invalid request) is reported and dropped.
  discard_on(Stripe::StripeError) { |job, error| job.report(error) }
  retry_on(*TRANSIENT_ERRORS, wait: :polynomially_longer, attempts: 5) { |job, error| job.report(error) }
  # The record was deleted before the job ran
  discard_on ActiveJob::DeserializationError

  def perform(record)
    Stripe::PaymentIntent.update(record.stripe_payment_intent_id, description: description(record).truncate(1000),
                                                                  metadata: metadata(record))
    Rails.logger.info "[LinkStripePaymentJob] linked payment intent #{record.stripe_payment_intent_id} to #{record.class.name} #{record.id}"
  end

  def report(error)
    record = arguments.first
    Rails.error.report(error, handled: true, severity: :warning,
                              context: { job: self.class.name, record: "#{record.class.name} #{record.try(:id)}",
                                         payment_intent_id: record.try(:stripe_payment_intent_id) })
  end

  private

  def description(record)
    case record
    when Order then "Order ##{record.id} - #{record.menu.name} - #{record.item_list}"
    when CreditItem then "Credits ##{record.id} - #{StripeCheckout::Fulfillment.credits_description(record.quantity)}"
    end
  end

  # Stripe merges metadata, so the purchase_* keys the webhook reads are kept.
  def metadata(record)
    record.is_a?(Order) ? { order_id: record.id } : { credit_item_id: record.id }
  end
end
