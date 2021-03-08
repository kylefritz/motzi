json.extract! @menu, :id

json.ordering_deadline_text ordering_deadline_text(@menu)

json.pickup_days @menu.pickup_days do |pickup_day|
  json.extract! pickup_day, :id, :pickup_at, :order_deadline_at
  json.debug pickup_day.day_abbr
end

json.items @menu.menu_items.map do |menu_item|
  item = menu_item.item

  json.extract! item, :id, :name, :description, :price, :credits
  json.image item.image_path

  json.extract! menu_item, :subscriber, :marketplace
  json.pickup_days menu_item.menu_item_pickup_days do |mi_pd|

    json.extract! mi_pd.pickup_day, :id, :pickup_at, :order_deadline_at
    json.debug mi_pd.pickup_day.day_abbr
  end
end