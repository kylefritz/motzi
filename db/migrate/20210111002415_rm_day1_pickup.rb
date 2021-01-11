class RmDay1Pickup < ActiveRecord::Migration[6.0]
  def change
    remove_column :order_items, :day1_pickup, null: false
    change_column_null :order_items, :pickup_day_id, false
  end
end
