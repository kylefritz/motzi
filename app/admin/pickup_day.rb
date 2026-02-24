ActiveAdmin.register PickupDay do
  permit_params :menu_id, :pickup_at, :order_deadline_at
  menu false
end
