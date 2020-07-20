json.menu do
  json.extract! @menu, :id, :name, :menu_note, :subscriber_note, :created_at, :day1_deadline, :day2_deadline
  json.is_current @menu.current?

  menu_items = @menu.menu_items.map {|mi| [mi, mi.item]}
  menu_items.push([MenuItem.new, Item.pay_it_forward])

  json.items menu_items.map do |menu_item, item|
    json.extract! menu_item, :subscriber, :marketplace, :day1, :day2
    json.extract! item, :id, :name, :description, :price
    json.image item.image_path
  end

  json.day1 Setting.pickup_day1
  json.day2 Setting.pickup_day2
  json.day1_deadline_day Setting.pickup_day1_deadline_day
  json.day2_deadline_day Setting.pickup_day2_deadline_day
end

json.user do
  if @user
    json.extract! @user, :id, :name, :email, :hashid, :credits, :breads_per_week, :send_weekly_email
  else
    json.null!
  end
end

json.order do
  if @order
    json.extract! @order, :id, :comments, :skip, :stripe_receipt_url, :stripe_charge_amount
    json.items @order.order_items.map do |order_item|
      json.extract! order_item, :item_id, :quantity, :day1_pickup, :day
    end
  else
    json.null!
  end
end
