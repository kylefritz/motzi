ActiveAdmin.register MenuItem do
  permit_params :menu_id, :item_id, :subscriber, :marketplace, :day1, :day2
  menu false
end
