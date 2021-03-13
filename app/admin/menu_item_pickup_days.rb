ActiveAdmin.register MenuItemPickupDay do
  permit_params :menu_item_id, :pickup_day_id, :limit
  menu false
end
