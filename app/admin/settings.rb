ActiveAdmin.register Setting do
  menu parent: 'Developer', priority: 4
  permit_params :var, :value

  config.filters = false
end
