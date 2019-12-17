json.id @menu.id
json.items @menu.menu_items.is_not_add_on do |menu_item|
  json.extract! menu_item.item, :name, :id
end
