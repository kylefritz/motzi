ActiveAdmin.register Setting do
  permit_params :var, :value

  config.filters = false
end
