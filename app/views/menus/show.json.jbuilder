json.menu do
  json.partial! 'menus/menu', menu: @menu
end

json.user do
  if @user
    json.extract! @user, :id, :name, :email, :hashid, :credits, :breads_per_week, :subscriber
  else
    json.null!
  end
end

json.order do
  json.partial! 'menus/order', order: @order
end

json.bundles CreditBundle.all do |b|
  json.extract! b, :name, :description, :credits, :price, :breads_per_week
end

json.holiday_menu do
  if @holiday_menu
    json.partial! 'menus/menu', menu: @holiday_menu
  else
    json.null!
  end
end

json.holiday_order do
  json.partial! 'menus/order', order: @holiday_order
end
