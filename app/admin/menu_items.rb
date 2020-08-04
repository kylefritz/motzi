ActiveAdmin.register MenuItem do
  permit_params :menu_id, :item_id, :subscriber, :marketplace, :day1, :day2, :day1_limit, :day2_limit
  menu false
end
