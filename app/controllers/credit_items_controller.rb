class CreditItemsController < ApplicationController
  include UserHashidable

  def create
    price = params[:price].to_f.clamp(1, 250)
    price_cents = (price * 100).to_i
    credits = params[:credits].to_i.clamp(1, 50)

    breads_per_week = params[:breads_per_week].to_f
    frequency = breads_per_week == 1.0 ? "Weekly" : "Bi-Weekly";

    begin
      # make stripe change
      charge = Stripe::Charge.create({
        amount: price_cents,
        currency: 'usd',
        source: params[:token],
        metadata: {credits: credits},
        description: "#{credits}x Subscription Credits, #{frequency}",
        receipt_email: current_user.email
      })

      # add credit_item for user
      @credit_item = current_user.credit_items.create!(stripe_charge_id: charge.id,
                                                       stripe_receipt_url: charge.try(:receipt_url),
                                                       memo: "paid $#{price} via Stripe. #{frequency}",
                                                       quantity: credits,
                                                       good_for_weeks: 42)

      # update user bread_per_week
      current_user.update(breads_per_week: breads_per_week)

      # return a reasonable response object
      render "show", format: :json
    rescue Stripe::CardError => e
      # https://stripe.com/docs/api/errors/handling
      logger.warn "Stripe::CardError Status=#{e.http_status} Type=#{e.error.type} Charge ID=#{e.error.charge} \
        Code=#{e.error.code} cecline_code=#{e.error.decline_code} param=#{e.error.param} message=#{e.error.message}"

      render json: {error: e.error.message}.to_json, status: :unprocessable_entity
    end
  end
end
