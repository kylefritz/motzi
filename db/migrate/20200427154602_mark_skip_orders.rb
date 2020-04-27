class MarkSkipOrders < ActiveRecord::Migration[6.0]
  def change
    Order.where(skip: false).find_each do |order|
      if order.order_items.empty?
        order.update!(skip: true)
      end
    end
  end
end
