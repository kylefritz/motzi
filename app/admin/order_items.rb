ActiveAdmin.register OrderItem do
  permit_params :order, :item, :quantity, :pickup_day
  menu false
end
