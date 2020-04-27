class OrdersController < ApplicationController
  include UserHashidable
  include RenderCurrentOrder

  def create
    if current_user.current_order
      logger.warn "user=#{current_user.email} already placed an order. returning that order"
    else
      menu = Menu.current
      if params[:skip] && params[:cart].present?
        throw "Can't skip when have items in cart"
      end

      order_params = params.permit(:feedback, :comments, :skip).merge(menu: menu, user: current_user)

      Order.transaction do
        Order.create!(order_params).tap do |order|
          params[:cart].each do |cart_item_params|
            day1_pickup = !(Setting.pickup_day2.casecmp?(cart_item_params[:day])) # default to day 1
            order.order_items.create!(cart_item_params.permit(:item_id, :quantity).merge(day1_pickup: day1_pickup))
          end
        end
      end
    end

    return render_current_order
  end
end
