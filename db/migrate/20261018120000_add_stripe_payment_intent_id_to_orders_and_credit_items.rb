# PaymentIntents (#412): the browser and the payment_intent.succeeded webhook
# can both try to record the same payment, so the intent id is unique.
class AddStripePaymentIntentIdToOrdersAndCreditItems < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :stripe_payment_intent_id, :string
    add_index :orders, :stripe_payment_intent_id, unique: true, where: "stripe_payment_intent_id IS NOT NULL"

    add_column :credit_items, :stripe_payment_intent_id, :string
    add_index :credit_items, :stripe_payment_intent_id, unique: true, where: "stripe_payment_intent_id IS NOT NULL"
  end
end
