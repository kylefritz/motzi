json.extract! menu, :id, :name, :menu_note, :subscriber_note
json.is_current menu.current?
json.ordering_deadline_text ordering_deadline_text(menu)
json.enable_pay_what_you_can Setting.shop.pay_what_you_can

json.pickup_days menu.pickup_days do |pickup_day|
  json.extract! pickup_day, :id, :pickup_at, :order_deadline_at
  json.debug pickup_day.day_abbr
end

menu_items = menu.sorted_menu_items(includes: {item: {image_attachment: :blob}, menu_item_pickup_days: :pickup_day})
                  .map {|mi| [mi, mi.item]}
if Setting.shop.pay_it_forward && Item.pay_it_forward.present?
  menu_items.push([MenuItem.new, Item.pay_it_forward])
end

def remaining(limit, ordered)
  unless limit.present?
    return 120
  end
  (limit - (ordered || 0)).clamp(0, 120)
end

ordered_item_counts = menu.item_counts
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
