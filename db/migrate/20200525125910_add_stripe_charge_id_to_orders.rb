class AddStripeChargeIdToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :stripe_charge_id, :string
    add_column :orders, :stripe_receipt_url, :string
    add_column :orders, :stripe_charge_amount, :decimal, :precision => 8, :scale => 2

    add_column :credit_items, :stripe_charge_amount, :decimal, :precision => 8, :scale => 2
  end
end
