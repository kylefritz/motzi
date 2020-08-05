json.id @menu.id
json.items @menu.menu_items do |menu_item|
  json.extract! menu_item.item, :name, :id
end
