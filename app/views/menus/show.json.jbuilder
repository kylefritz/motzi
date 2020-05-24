json.menu do
  json.extract! @menu, :id, :name, :bakers_note, :created_at, :deadline
  json.is_current @menu.current?
  json.deadline_day Setting.deadline_day
  items = @menu.menu_items.reject(&:is_add_on?)

  json.items [items.map(&:item), Item.pay_it_forward].flatten.map do |item|
    json.extract! item, :id, :name, :description
    json.image item.image_path
  end
end

json.user do
  if @user
    json.extract! @user, :id, :name, :email, :hashid, :credits, :breads_per_week
  else
    json.null!
  end
end

json.order do
  if @order
    json.extract! @order, :id, :comments, :feedback, :skip
    json.items @order.order_items.map do |order_item|
      json.extract! order_item, :item_id, :quantity, :day1_pickup, :day
    end
  else
    json.null!
  end
end
