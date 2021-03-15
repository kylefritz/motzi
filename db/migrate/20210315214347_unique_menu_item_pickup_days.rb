class UniqueMenuItemPickupDays < ActiveRecord::Migration[6.0]
  def change

    add_index :menu_item_pickup_days, [:menu_item_id, :pickup_day_id], unique: true
  end
end
