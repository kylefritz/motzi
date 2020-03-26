class AddPickupDayToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :day1_pickup_maybe, :boolean
    add_index :orders, :day1_pickup_maybe
  end
end
