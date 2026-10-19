# How OrdersController and CreditItemsController answer the outcomes of a
# card payment (StripeCheckout), so the two checkouts respond alike.
module StripeCheckoutResponses
  extend ActiveSupport::Concern

  # Pages loaded before the PaymentIntents deploy still post a card `token`.
  # It can't be charged any more; ask them to reload instead of failing
  # further in (possibly after creating a guest).
  STALE_PAGE_MESSAGE = "Please reload the page and try again.".freeze

  included do
    before_action :reject_stale_card_token, only: :create

    rescue_from StripeCheckout::PaymentError do |e|
      render json: { message: e.message }, status: :unprocessable_content
    end

    # nothing was saved; the browser authenticates the card and posts again
    # with the payment intent id
    rescue_from StripeCheckout::RequiresAction do |e|
      render json: { requires_action: true, client_secret: e.client_secret }
    end

    # nothing was saved yet; the webhook records the purchase once it succeeds
    rescue_from StripeCheckout::Pending do |e|
      render json: { pending: true, message: e.message }, status: :accepted
    end

    # Stripe refused the request (an expired or reused confirmation token, an
    # unknown payment intent...), so nothing was charged.
    rescue_from Stripe::InvalidRequestError, Stripe::IdempotencyError do |e|
      # `endpoint`, not `controller`: that key would replace the request
      # context the error tracker records
      Rails.error.report(e, handled: true, severity: :warning,
                            context: { endpoint: "#{controller_name}##{action_name}", request_id: e.request_id, code: e.code })
      render json: { message: StripeCheckout::FAILED_MESSAGE }, status: :unprocessable_content
    end

    rescue_from Stripe::CardError do |e|
      # https://stripe.com/docs/api/errors/handling
      logger.warn "Stripe::CardError Status=#{e.http_status} Type=#{e.error.type} RequestId=#{e.request_id} " \
                  "Code=#{e.error.code} decline_code=#{e.error.decline_code} param=#{e.error.param} message=#{e.error.message}"
      render json: { message: e.error.message }, status: :unprocessable_content
    end
  end

  private

  def reject_stale_card_token
    return unless params[:token].present? && params[:confirmation_token_id].blank? && params[:payment_intent_id].blank?

    logger.warn "rejected a card token from a page loaded before PaymentIntents"
    render json: { message: STALE_PAGE_MESSAGE }, status: :unprocessable_content
  end

  # The price param in dollars, as a BigDecimal (0 when blank or junk).
  def price_param
    BigDecimal(params[:price].to_s, exception: false) || BigDecimal("0")
  end
end
