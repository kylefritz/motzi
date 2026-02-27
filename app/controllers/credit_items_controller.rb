class CreditItemsController < ApplicationController
  include UserHashidable
  before_action :require_hashid_user_or_devise_user!

  def create
    price = params[:price].to_f.clamp(1, CreditBundle::MAX_PRICE)
    price_cents = (price * 100).to_i
    quantity = params[:credits].to_i.clamp(1, CreditBundle::MAX_CREDITS)
    bundle = CreditBundle.find_by(credits: quantity)
    begin
      description = ["#{quantity}x credits", bundle.try(:name_description)].compact.join(" - ")
      # make stripe change
      charge = Stripe::Charge.create({
        amount: price_cents,
        currency: 'usd',
        source: params[:token],
        metadata: {
          user_id: current_user.id,
          user_name: current_user.name,
          credits: quantity,
          bundle_name: bundle.try(:name),
          bundle_description: bundle.try(:description),
        },
        description: description,
        receipt_email: current_user.email
      })

      # add credit_item for user
      @credit_item = current_user.credit_items.create!(stripe_charge_id: charge.id,
                                                       stripe_receipt_url: charge.try(:receipt_url),
                                                       stripe_charge_amount: price,
                                                       memo: "#{description}. Paid via Stripe $#{price}.",
                                                       quantity: quantity,
                                                       good_for_weeks: 42)

      # make user subscriber & update bread_per_week
      current_user.update(breads_per_week: params[:breads_per_week].to_f, subscriber: true)

      ConfirmationMailer.with(credit_item: @credit_item).credit_email.deliver_later

      # return a reasonable response object
      render "show", format: :json
    rescue Stripe::CardError => e
      # https://stripe.com/docs/api/errors/handling
      logger.warn "Stripe::CardError Status=#{e.http_status} Type=#{e.error.type} Charge ID=#{e.error.charge} \
        Code=#{e.error.code} cecline_code=#{e.error.decline_code} param=#{e.error.param} message=#{e.error.message}"

      render json: {error: e.error.message}.to_json, status: :unprocessable_content
    end
  end
end
