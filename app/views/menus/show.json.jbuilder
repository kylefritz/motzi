json.menu do
  json.extract! @menu, :id, :name, :menu_note, :subscriber_note
  json.is_current @menu.current?
  json.ordering_deadline_text ordering_deadline_text(@menu)
  json.enable_pay_what_you_can Setting.shop.pay_what_you_can

  json.pickup_days @menu.pickup_days do |pickup_day|
    json.extract! pickup_day, :id, :pickup_at, :order_deadline_at
    json.debug pickup_day.day_abbr
  end

  menu_items = @menu.menu_items.includes(item: {image_attachment: :blob}).map {|mi| [mi, mi.item]}
  if Setting.shop.pay_it_forward && Item.pay_it_forward.present?
    menu_items.push([MenuItem.new, Item.pay_it_forward])
  end

  def remaining(limit, ordered)
    unless limit.present?
      return 120
    end
    (limit - (ordered || 0)).clamp(0, 120)
  end

  ordered_item_counts = @menu.item_counts
  json.items menu_items.map do |menu_item, item|
    json.extract! item, :id, :name, :description, :price, :credits
    json.image item.image_path

    json.extract! menu_item, :subscriber, :marketplace
    json.pickup_days menu_item.menu_item_pickup_days do |mi_pd|

      json.extract! mi_pd.pickup_day, :id, :pickup_at, :order_deadline_at
      json.debug mi_pd.pickup_day.day_abbr
      json.remaining remaining(mi_pd.limit, (ordered_item_counts[item.id] || {})[mi_pd.pickup_day_id])
    end
  end
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
      json.extract! order_item, :item_id, :quantity, :day, :pickup_day_id
      json.extract! order_item.pickup_day, :pickup_at
    end
  else
    json.null!
  end
end

json.bundles CreditBundle.all do |b|
  json.extract! b, :name, :description, :credits, :price, :breads_per_week
end
