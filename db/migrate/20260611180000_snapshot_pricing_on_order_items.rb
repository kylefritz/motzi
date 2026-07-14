class SnapshotPricingOnOrderItems < ActiveRecord::Migration[7.2]
  def up
    add_column :order_items, :credits, :integer
    add_column :order_items, :price, :decimal, precision: 8, scale: 2

    # Best available backfill: the item's current pricing. Historical orders
    # placed before a reprice will reflect today's values, but from here on
    # order_items are immutable records of what the order cost.
    execute <<~SQL
      UPDATE order_items
      SET credits = items.credits, price = items.price
      FROM items
      WHERE items.id = order_items.item_id
    SQL

    change_column_null :order_items, :credits, false
    change_column_null :order_items, :price, false
  end

  def down
    remove_column :order_items, :credits
    remove_column :order_items, :price
  end
end
