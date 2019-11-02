ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :additional_email, :is_first_half, :is_admin, :send_weekly_email
  config.sort_order = 'last_name_asc'

  scope("all") { |scope| scope }
  scope("tues") { |scope| scope.where(is_first_half: true) }
  scope("thurs") { |scope| scope.where(is_first_half: false) }
  scope("admin") { |scope| scope.where(is_admin: true) }
  scope("no weekly email") { |scope| scope.where(send_weekly_email: false) }

  index do
    selectable_column()
    actions
    column :first_name
    column :last_name
    column :email
    column :additional_email
    column :is_first_half
    column :send_weekly_email
    column :is_admin
    column :created_at
    column :updated_at
  end

  form title: 'A custom title' do |f|
    inputs 'Details' do
      input :first_name
      input :last_name
      input :email
      input :additional_email
      input :is_first_half
    end
    inputs 'Danger Zone' do
      input :send_weekly_email
      input :is_admin
    end
    actions
  end

  actions :all, except: [:destroy] # deleting users can orphan orders, etc
end
