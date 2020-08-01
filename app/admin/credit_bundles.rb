ActiveAdmin.register CreditBundle do
  permit_params :name, :description, :credits, :price, :breads_per_week, :sort_order

  preserve_default_filters!
  remove_filter :versions
end
