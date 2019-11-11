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
    column :first_name
    column :last_name
    column :email do |user|
      para user.email
      small user.additional_email
    end
    column :is_first_half
    column :send_weekly_email
    column :is_admin
    column :created_at
    column :updated_at
    actions
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

  show do |user|

    panel "Orders" do
      table_for user.orders do
        column "menu" do |order|
          auto_link order.menu
        end
        column :order do |order|
          auto_link order
        end
        column :items do |order|
          render partial: 'admin/orders/items', locals: {items: order.items}
        end
        column :feedback
        column :comments
      end
    end

    attributes_table do
      row :name
      row :email do |user|
        para strong auto_link user.email
        small user.additional_email
      end
      row :is_first_half
      row :send_weekly_email
      row :is_admin
      row :created_at
      row :updated_at      
    end

    panel "Emails" do
      table_for user.messages do
        column "menu" do |email|
          auto_link email.menu
        end
        column :sent_at
        column :opened_at
        column :clicked_at
        column :to
        column :subject
        column :mailer
      end
    end

    active_admin_comments
  end

  actions :all, except: [:destroy] # deleting users can orphan orders, etc
end
