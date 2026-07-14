class AddOrderIdToAhoyMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :ahoy_messages, :order_id, :bigint
    add_index :ahoy_messages, :order_id
  end
end
