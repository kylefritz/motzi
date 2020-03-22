json.credit_item do
  json.extract! @credit_item, :id, :stripe_charge_id, :stripe_receipt_url, :memo, :quantity, :user_id
end
