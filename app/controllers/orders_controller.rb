class OrdersController < ApplicationController
  include UserHashidable
  include RenderCurrentOrder
  before_action :require_not_skip_and_cart_items

  def create
    if current_user.current_order
      logger.warn "user=#{current_user.email} already placed an order. returning that order"
      return render_current_order
    end
    menu = Menu.current

    if menu.ordering_closed? && current_admin_user.blank?
      return render_ordering_closed
    end

    order_params = params.permit(:feedback, :comments, :skip).merge(menu: menu, user: current_user)

    Order.transaction do
      Order.create!(order_params).tap do |order|
        params[:cart].each do |cart_item_params|
          day1_pickup = !(Setting.pickup_day2.casecmp?(cart_item_params[:day])) # default to day 1
          order.order_items.create!(cart_item_params.permit(:item_id, :quantity).merge(day1_pickup: day1_pickup))
        end
        ahoy.track "order_created"
      end
    end

    render_current_order
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
      order.update!(params.permit(:feedback, :comments, :skip))
      order.order_items.destroy_all
      params[:cart].each do |cart_item_params|
        day1_pickup = !(Setting.pickup_day2.casecmp?(cart_item_params[:day])) # default to day 1
        order.order_items.create!(cart_item_params.permit(:item_id, :quantity).merge(day1_pickup: day1_pickup))
      end
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
    render json: { message: "ordering for this menu is closed" }, status: :unprocessable_entity
  end
end
