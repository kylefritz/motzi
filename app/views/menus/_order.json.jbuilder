if order
  json.extract! order, :id, :comments, :skip, :stripe_receipt_url, :stripe_charge_amount
  json.items order.order_items.map do |order_item|
    json.extract! order_item, :item_id, :quantity, :day, :pickup_day_id
    json.extract! order_item.pickup_day, :pickup_at
  end
else
  json.null!
end
