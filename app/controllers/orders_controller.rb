class OrdersController < ApplicationController
  def create
    menu = Menu.find(params[:menu])

    order = Order.transaction do
        Order.create!(menu: menu, user: current_user).tap do |order|
            # TODO: right now just picking first item
            order.order_items.create!(item: menu.items.first)
        end
    end

    order
  end
end
