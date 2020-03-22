class AddStripeChargeIdToCreditItems < ActiveRecord::Migration[6.0]
  def change
    add_column :credit_items, :stripe_charge_id, :string
    add_column :credit_items, :stripe_receipt_url, :string
  end
end
