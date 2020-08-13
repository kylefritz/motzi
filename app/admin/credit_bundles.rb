ActiveAdmin.register CreditBundle do
  permit_params :name, :description, :credits, :price, :breads_per_week, :sort_order

  config.filters = false
end
