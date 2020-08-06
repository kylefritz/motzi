json.id @menu.id
json.items @menu.menu_items do |menu_item|
  json.extract! menu_item, :subscriber, :marketplace, :day1, :day2, :day1_limit, :day2_limit
  json.menu_item_id menu_item.id

  json.extract! menu_item.item, :id, :name, :description, :price, :credits
end
