class CreditItemsController < ApplicationController
  include UserHashidable
  before_action :require_hashid_user_or_devise_user!

  def create
    price = params[:price].to_f.clamp(1, CreditBundle::MAX_PRICE)
    quantity = params[:credits].to_i.clamp(1, CreditBundle::MAX_CREDITS)
    bundle = CreditBundle.find_by(credits: quantity)
    description = StripeCheckout::Fulfillment.credits_description(quantity)

    # charge the card, or verify the payment the browser just authenticated
    payment = StripeCheckout.new(
      kind: "credits",
      amount_cents: (price * 100).round,
      email: current_user.email,
      description: description,
      purchase: { user_id: current_user.id, credits: quantity },
      metadata: {
        user_name: current_user.name,
        bundle_name: bundle.try(:name),
        bundle_description: bundle.try(:description),
        breads_per_week: params[:breads_per_week].to_f
      }
    ).pay!(confirmation_token_id: params[:confirmation_token_id], payment_intent_id: params[:payment_intent_id])

    # add credit_item for user, unless the payment_intent.succeeded webhook
    # already did
    @credit_item = begin
      CreditItem.find_by(stripe_payment_intent_id: payment.payment_intent_id) ||
        StripeCheckout::Fulfillment.add_credits!(user: current_user, quantity: quantity, description: description,
                                                 payment: payment, breads_per_week: params[:breads_per_week])
    rescue ActiveRecord::RecordNotUnique
      CreditItem.find_by!(stripe_payment_intent_id: payment.payment_intent_id)
    end

    # return a reasonable response object
    render "show", format: :json
  rescue StripeCheckout::RequiresAction => e
    # nothing was saved; the browser authenticates the card and posts again
    # with the payment intent id
    render json: { requires_action: true, client_secret: e.client_secret }
  rescue StripeCheckout::PaymentError => e
    render json: { message: e.message }, status: :unprocessable_content
  rescue Stripe::CardError => e
    # https://stripe.com/docs/api/errors/handling
    logger.warn "Stripe::CardError Status=#{e.http_status} Type=#{e.error.type} RequestId=#{e.request_id} \
      Code=#{e.error.code} decline_code=#{e.error.decline_code} param=#{e.error.param} message=#{e.error.message}"

    render json: { message: e.error.message }, status: :unprocessable_content
  end
end
