class OrdersController < ApplicationController
  include UserHashidable
  include RenderCurrentOrder

  def create
    if current_user.current_order
      logger.warn "user=#{current_user.email} already placed an order. returning that order"
    else
      menu = Menu.current
      order_params = params.permit(:feedback, :comments).merge(menu: menu, user: current_user)

      order = Order.transaction do
        Order.create!(order_params).tap do |order|
          params[:items].map do |item_id|
            order.order_items.create!(item_id: item_id)
          end
        end
      end
    end

    return render_current_order
  end
end
