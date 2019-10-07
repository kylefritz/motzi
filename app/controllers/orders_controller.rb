class OrdersController < ApplicationController
  def create
    # TODO: don't let subscriber place order twice
    menu = Menu.current
    order_params = params.permit(:feedback, :comments).merge(menu: menu, user: current_user)

    order = Order.transaction do
        Order.create!(order_params).tap do |order|
          params[:items].map do |item_id|
            order.order_items.create!(item_id: item_id)
          end
        end
    end

    render json: nil
  end
end
