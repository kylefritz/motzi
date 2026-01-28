json.extract! @menu, :id

json.ordering_deadline_text ordering_deadline_text(@menu)

json.leadtime_hours Setting.leadtime_hours

json.recent_menus Menu.unscoped.includes(:pickup_days).order("LOWER(week_id) desc").limit(100) do |menu|
  json.extract! menu, :id, :name, :week_id
  json.pickup_days_label menu.pickup_days.map(&:day_abbr).join(", ")
end

json.pickup_days @menu.pickup_days do |pickup_day|
  json.extract! pickup_day, :id, :pickup_at, :order_deadline_at, :deadline_text
  json.debug pickup_day.day_abbr
end

json.items @menu.sorted_menu_items.map do |menu_item|
  item = menu_item.item

  json.menu_item_id menu_item.id
  json.item_id menu_item.item_id

  json.extract! item, :name, :description, :price, :credits
  json.image item.image_path

  json.extract! menu_item, :subscriber, :marketplace, :sort_order
  json.pickup_days menu_item.menu_item_pickup_days do |mi_pd|

    json.extract! mi_pd, :id, :limit
    json.extract! mi_pd.pickup_day, :pickup_at, :order_deadline_at, :deadline_text
    json.debug mi_pd.pickup_day.day_abbr
  end
end
