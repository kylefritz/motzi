class CreditsController < ApplicationController
  include UserHashidable

  def create
    weekly? = params[:choice] == "weekly"
    price = weekly? ? 172 : 94

    Stripe::Charge.create({
      amount: price,
      currency: 'usd',
      source: params[:token],
      description: "Motzi bread subscription #{params[:choice]}",
    })

    # TODO set strip api key
    # TODO give user credits
    # TODO return a reasonable response object

    return render_current_order
  end
end
