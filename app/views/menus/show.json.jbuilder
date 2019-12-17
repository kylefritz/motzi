json.menu do
  json.extract! @menu, :id, :name, :bakers_note, :created_at
  json.is_current @menu.current?

  addons, items = @menu.menu_items.partition(&:is_add_on?)

  json.items items.map do |menu_item|
    json.partial! "menus/item.json.jbuilder", menu_item: menu_item
  end
  json.addons addons.map do |menu_item|
    json.partial! "menus/item.json.jbuilder", menu_item: menu_item
  end
end

json.user do
  if @user
    json.extract! @user, :id, :name, :email, :hashid, :credits, :tuesday_pickup
  else
    json.null!
  end
end

json.order do
  if @order
    json.items @order.order_items.map do |item|
      json.extract! item, :item_id
    end
  else
    json.null!
  end
end
