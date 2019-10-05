ActiveAdmin.register OrderItem do
  permit_params :order, :item
end