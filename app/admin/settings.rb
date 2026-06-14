ActiveAdmin.register Setting do
  menu parent: "Advanced", priority: 6
  permit_params :var, :value

  config.filters = false
end
