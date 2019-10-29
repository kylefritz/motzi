json.menu do
  json.extract @menu, :id, :name, :bakers_note, :created_at

  addons, items = @menu.menu_items.partition(&:is_add_on?)

  json.items items.map do |menu_item|
    json.partial! "item.json.jbuilder", menu_item: menu_item
  end
  json.addons addons.map do |menu_item|
    json.partial! "item.json.jbuilder", menu_item: menu_item
  end
end

json.user current_user.name
json.credits current_user.credits
