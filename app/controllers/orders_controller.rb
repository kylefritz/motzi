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

    User.create!(params.permit(:first_name, :last_name, :email, :phone, :opt_in))
  end

  def create
    target_menu = params[:menu_id].present? ? Menu.find(params[:menu_id]) : Menu.current

    if current_user&.order_for_menu(target_menu).present?
      logger.warn "user=#{current_user.email} already placed an order for menu #{target_menu.id}. returning current order"
      return render_current_order
    end
    @menu = target_menu

    if @menu.ordering_closed? && current_admin_user.blank?
      return render_ordering_closed
    end

    @user, @order = Order.transaction do
      user = current_user_or_create_user
      order_params = params.permit(:comments, :skip).merge(menu: @menu, user: user)

      order = Order.create!(order_params)
      unless order.skip?
        if params.fetch(:cart).empty?
          raise OrderError.new("Add an item to your cart")
        end
      end
      params.fetch(:cart).each do |cart_item_params|
        # Create a clean hash with only permitted attributes and ensure quantity is not null
        filtered_params = {
          item_id: cart_item_params[:item_id],
          quantity: cart_item_params[:quantity].presence || 1,
          pickup_day_id: cart_item_params[:pickup_day_id] || @menu.pickup_days.first.id
        }

        order.order_items.create!(filtered_params)
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
              user_id: user.id,
              order_id: order.id,
            },
            description: "Order ##{order.id} - #{order.item_list}",
            receipt_email: user.email
          })
        end
        order.update!(
          stripe_charge_id: charge.try(:id),
          stripe_receipt_url: charge.try(:receipt_url),
          stripe_charge_amount: price,
        )
      end

      ahoy.track "order_created"
      [user, order]
    end

    # send confirmation email
    ConfirmationMailer.with(order: @order).order_email.deliver_later

    # Render directly (not via render_current_order) so that @order
    # reflects the just-created order — including marketplace orders,
    # which order_for_menu intentionally excludes.
    @menu = Menu.current
    @holiday_menu  = Menu.current_holiday
    @holiday_order = @user&.order_for_menu(@holiday_menu) if @holiday_menu
    render 'menus/show', format: :json

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
        # Create a clean hash with only permitted attributes and ensure quantity is not null
        filtered_params = {
          item_id: cart_item_params[:item_id],
          quantity: cart_item_params[:quantity].presence || 1,
          pickup_day_id: cart_item_params[:pickup_day_id] || order.menu.pickup_days.first.id
        }
        
        order.order_items.create!(filtered_params)
      end

      # send confirmation email
      ConfirmationMailer.with(order: order).order_email.deliver_later

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
