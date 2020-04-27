class RmDayFromOrders < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :day1_pickup_maybe

    change_column_null :order_items, :day1_pickup, false
    change_column_default :order_items, :day1_pickup, from: nil, to: true
  end
end
