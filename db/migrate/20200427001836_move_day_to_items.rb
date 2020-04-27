class MoveDayToItems < ActiveRecord::Migration[6.0]
  def change
    Order.find_each do |order|
      order.order_items.update_all(day1_pickup: day1_pickup?(order))
    end
  end

  private

  def day1_pickup?(order)
    # if value on order is nil, fall back to value on user
    if order.day1_pickup_maybe.nil?
      if order.user
        order.user.day1_pickup?
      else
        true
      end
    else
      order.day1_pickup_maybe
    end
  end
end
