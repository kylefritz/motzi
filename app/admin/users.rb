ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :password, :additional_email, :credits, :is_first_half, :is_admin, :send_weekly_email
  config.sort_order = 'last_name_asc'

  actions :all, except: [:destroy] # deleting users can orphan orders, etc
end
