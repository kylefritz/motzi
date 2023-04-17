class PaymentIntentsController < ApplicationController
  include UserHashidable
  
  def current_user_or_create_user
    if !params.include?(:email)
      logger.warn "no email coming from user"
      require_hashid_user_or_devise_user!
      return current_user
    end

    if (existing_user = User.find_by(email: params.fetch(:email).strip.downcase)).present?
      return existing_user
    end

    User.create!(params.permit(:first_name, :last_name, :email, :phone, :opt_in))
  end

  def create
    # TODO: i need the cart here like i have in orders controller

    user = current_user_or_create_user
    # this is a "pay what you can" app
    # so it's ok to trust customer input
    price = params[:price].to_f.clamp(0, 250)
    price_cents = (price * 100).to_i

    description = params[:description] || "#{ShopConfig.name} order"

    payment_intent = Stripe::PaymentIntent.create(
      amount: price_cents,
      currency: 'usd',
      automatic_payment_methods: { enabled: true },
      description: description,
      receipt_email: user.email
    )

    return render json: { client_secret: payment_intent['client_secret'] }
  end
end