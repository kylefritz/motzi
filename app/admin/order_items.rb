ActiveAdmin.register OrderItem do
  permit_params :order, :item, :quantity, :day1_pickup
  menu false
end
