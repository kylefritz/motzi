class OrdersController < ApplicationController
  class OrderError < StandardError;end

  include UserHashidable
  include RenderCurrentOrder
  before_action :require_not_skip_and_cart_items

  def current_user_or_create_user
    if !params.include?(:email)
      require_hashid_user_or_devise_user!
      return current_user
    end

    if (existing_user = User.find_by(email: params.fetch(:email).strip.downcase)).present?
      return existing_user
    end

    User.create!(params.permit(:first_name, :last_name, :email, :opt_in))
  end

  def create
    if current_user&.current_order
      logger.warn "user=#{current_user.email} already placed an order. returning that order"
      return render_current_order
    end
    menu = Menu.current

    if menu.ordering_closed? && current_admin_user.blank?
      return render_ordering_closed
    end

    current_user, order = Order.transaction do
      current_user = current_user_or_create_user
      order_params = params.permit(:comments, :skip).merge(menu: menu, user: current_user)

      order = Order.create!(order_params)
      unless order.skip?
        if params.fetch(:cart).empty?
          raise OrderError.new("Add an item to your cart")
        end
      end
      params.fetch(:cart).each do |cart_item_params|
        day1_pickup = !(Setting.pickup_day2.casecmp?(cart_item_params[:day])) # default to day 1
        order.order_items.create!(cart_item_params.permit(:item_id, :quantity).merge(day1_pickup: day1_pickup))
      end

      # figure out if we need to charge this person or if we're using credits
      if params[:price].present?

        # we let the customer set the price so ok to trust customer input
        price = params[:price].to_f.clamp(0, 250)
        price_cents = (price * 100).to_i

        # make stripe change
        if price > 0
          if params[:token].blank?
            raise OrderError.new("Stripe credit card not submitted")
          end
          charge = Stripe::Charge.create({
            amount: price_cents,
            currency: 'usd',
            source: params[:token],
            metadata: {
              user_id: current_user.id,
              order_id: order.id,
            },
            description: "Order ##{order.id} - #{order.item_list}",
            receipt_email: current_user.email
          })
        end
        order.update!(
          stripe_charge_id: charge.try(:id),
          stripe_receipt_url: charge.try(:receipt_url),
          stripe_charge_amount: price,
        )
      end

      ahoy.track "order_created"
      [current_user, order]
    end

    # send confirmation email
    OrderMailer.with(order: order).confirmation_email.deliver_later

    render_current_order(menu.id, current_user)

    rescue OrderError => e
      render_validation_failed(e.message)
    rescue Stripe::CardError => e
      # https://stripe.com/docs/api/errors/handling
      logger.warn "Stripe::CardError Status=#{e.http_status} Type=#{e.error.type} Charge ID=#{e.error.charge} \
        Code=#{e.error.code} decline_code=#{e.error.decline_code} param=#{e.error.param} message=#{e.error.message}"

      render_validation_failed(e.error.message)
  end

  def update
    order = Order.find(params[:id])

    if current_admin_user.blank?
      if order.user_id != current_user.id
        return render json: { message: "not your order" }, status: :unauthorized
      end

      if order.menu.ordering_closed?
        return render_ordering_closed
      end
    end

    Order.transaction do
      order.update!(params.permit(:comments, :skip))
      order.order_items.destroy_all
      params[:cart].each do |cart_item_params|
        day1_pickup = !(Setting.pickup_day2.casecmp?(cart_item_params[:day])) # default to day 1
        order.order_items.create!(cart_item_params.permit(:item_id, :quantity).merge(day1_pickup: day1_pickup))
      end

      # send confirmation email
      OrderMailer.with(order: order).confirmation_email.deliver_later

      ahoy.track "order_updated"
    end

    render_current_order
  end

  private
  def require_not_skip_and_cart_items
    if params[:skip] && params[:cart].present?
      throw "Can't skip when have items in cart"
    end
  end

  def render_ordering_closed
    return render_validation_failed("ordering for this menu is closed")
  end

  def render_validation_failed(message)
    return render json: { message: message }, status: :unprocessable_entity
  end
end
