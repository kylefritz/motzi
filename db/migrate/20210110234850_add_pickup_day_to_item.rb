class AddPickupDayToItem < ActiveRecord::Migration[6.0]
  def change
    add_column :order_items, :pickup_day_id, :bigint
  end
end
