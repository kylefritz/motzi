json.menu do
  json.extract! @menu, :id, :name, :menu_note, :subscriber_note, :created_at, :day1_deadline, :day2_deadline
  json.is_current @menu.current?

  menu_items = @menu.menu_items.includes(item: {image_attachment: :blob}).map {|mi| [mi, mi.item]}
  if Setting.shop.pay_it_forward && Item.pay_it_forward.present?
    menu_items.push([MenuItem.new, Item.pay_it_forward])
  end

  day1_counts, day2_counts = @menu.item_counts

  def remaining(limit, ordered, is_for_day)
    unless is_for_day
      return nil
    end
    unless limit.present?
      return 120
    end
    (limit - (ordered || 0)).clamp(0, 120)
  end

  json.items menu_items.map do |menu_item, item|
    json.extract! item, :id, :name, :description, :price, :credits
    json.image item.image_path

    json.extract! menu_item, :subscriber, :marketplace, :day1, :day2
    json.remaining_day1 remaining(menu_item.day1_limit, day1_counts[menu_item.item_id], menu_item.day1)
    json.remaining_day2 remaining(menu_item.day2_limit, day2_counts[menu_item.item_id], menu_item.day2)
  end

  json.day1 Setting.pickup_day1
  json.day2 Setting.pickup_day2
  json.ordering_deadline_text ordering_deadline_text()

  json.enable_pay_what_you_can Setting.shop.pay_what_you_can
end

json.user do
  if @user
    json.extract! @user, :id, :name, :email, :hashid, :credits, :breads_per_week, :subscriber
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

json.bundles CreditBundle.all do |b|
  json.extract! b, :name, :description, :credits, :price, :breads_per_week
end
