ActiveAdmin.register CreditBundle do
  menu parent: 'Credits', label: 'Bundles', priority: 1
  permit_params :name, :description, :credits, :price, :breads_per_week, :sort_order

  config.filters = false
end
