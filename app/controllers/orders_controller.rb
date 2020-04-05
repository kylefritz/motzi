class OrdersController < ApplicationController
  include UserHashidable
  include RenderCurrentOrder

  def create
    if current_user.current_order
      logger.warn "user=#{current_user.email} already placed an order. returning that order"
    else
      menu = Menu.current
      order_params = params.permit(:feedback, :comments).merge(menu: menu, user: current_user)

      if params[:day].present?
        # TODO: fix params[:day] == "saturday"
        day1_pickup = !(params[:day] == "saturday")
        order_params[:day1_pickup_maybe] = day1_pickup
      end

      order = Order.transaction do
        Order.create!(order_params).tap do |order|
          params[:items].map do |item_id|
            order.order_items.create!(item_id: item_id)
            unless day1_pickup.nil?
              current_user.update!(day1_pickup: day1_pickup)
            end
          end
        end
      end
    end

    return render_current_order
  end
end
