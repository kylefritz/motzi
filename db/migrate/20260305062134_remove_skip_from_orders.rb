class RemoveSkipFromOrders < ActiveRecord::Migration[7.2]
  def up
    Order.where(skip: true).delete_all
    remove_column :orders, :skip
  end

  def down
    add_column :orders, :skip, :boolean, default: false, null: false
  end
end
