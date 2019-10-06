ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :password, :additional_email, :credits, :is_first_half, :is_admin
  config.sort_order = 'last_name_asc'
end