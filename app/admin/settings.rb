ActiveAdmin.register Setting do
  permit_params :var, :value

  preserve_default_filters!
  remove_filter :versions
end
