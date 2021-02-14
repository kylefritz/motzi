class CreateMenuItemPickupDays < ActiveRecord::Migration[6.0]
  def change
    create_table :menu_item_pickup_days do |t|
      t.references :menu_item, null: false
      t.references :pickup_day, null: false
      t.integer :limit, null: true

      t.timestamps
    end
  end
end
