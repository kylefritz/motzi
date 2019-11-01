class AddAhoyToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :ahoy_visit_id, :bigint
  end
end
