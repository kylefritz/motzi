class CreditItemsController < ApplicationController
  include UserHashidable
  include StripeCheckoutResponses
  before_action :require_hashid_user_or_devise_user!

  def create
    # Finishing a card payment after 3D Secure: the money has moved, so the
    # credits are added from the payment, without re-running checkout.
    return record_paid_credits if params[:payment_intent_id].present?

    quantity = params[:credits].to_i.clamp(1, CreditBundle::MAX_CREDITS)
    price_cents = credits_price_cents(quantity)
    bundle = CreditBundle.find_by(credits: quantity)
    description = StripeCheckout::Fulfillment.credits_description(quantity)

    payment = StripeCheckout.new(
      kind: "credits",
      amount_cents: price_cents,
      email: current_user.email,
      description: description,
      purchase: { user_id: current_user.id, credits: quantity },
      metadata: {
        user_name: current_user.name,
        bundle_name: bundle.try(:name),
        bundle_description: bundle.try(:description),
        breads_per_week: params[:breads_per_week].to_f
      }
    ).charge!(params[:confirmation_token_id])

    # add credit_item for user, unless the payment_intent.succeeded webhook
    # already did
    @credit_item = begin
      StripeCheckout::Fulfillment.add_credits!(user: current_user, quantity: quantity, description: description,
                                               payment: payment, breads_per_week: params[:breads_per_week])
    rescue ActiveRecord::RecordNotUnique
      CreditItem.find_by!(stripe_payment_intent_id: payment.payment_intent_id)
    end

    # return a reasonable response object
    render "show", format: :json
  end

  private

  # What to charge, in cents. With pay what you can on, a member may pay any
  # amount from $1 to CreditBundle::MAX_PRICE (the card form uses the same
  # bounds); with it off, a bundle's price exactly.
  def credits_price_cents(quantity)
    price_cents = StripeCheckout.to_cents(price_param)

    unless Setting.shop.pay_what_you_can
      bundle_cents = CreditBundle.find_by(credits: quantity)&.price&.then { |price| StripeCheckout.to_cents(price) }
      raise StripeCheckout::PaymentError, "Please choose one of the credit bundles" unless bundle_cents == price_cents

      return price_cents
    end

    unless price_cents.between?(100, CreditBundle::MAX_PRICE * 100)
      raise StripeCheckout::PaymentError, "Credit purchases must be between $1.00 and $#{CreditBundle::MAX_PRICE}.00"
    end

    price_cents
  end

  # The 3D Secure leg: add the credits the verified payment paid for, which
  # must have been bought by this member.
  def record_paid_credits
    intent = StripeCheckout.paid_intent!(params[:payment_intent_id], kind: "credits") do |metadata|
      metadata["purchase_user_id"] == current_user.id.to_s
    end
    @credit_item = StripeCheckout::Fulfillment.record!(intent, source: "credit_purchase")
    raise StripeCheckout::PaymentError, StripeCheckout::REJECTED_MESSAGE unless @credit_item

    render "show", format: :json
  end
end
