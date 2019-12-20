ActiveAdmin.register OrderItem do
  permit_params :order, :item
  menu false
end
