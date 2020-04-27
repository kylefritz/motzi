class AddDayQuantityToOrderItems < ActiveRecord::Migration[6.0]
  def change
    add_column :order_items, :quantity, :integer, default: 1, null: false
    add_column :order_items, :day1_pickup, :boolean
  end
end
