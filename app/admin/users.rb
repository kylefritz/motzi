ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :additional_email, :tuesday_pickup, :is_admin, \
    :send_weekly_email, :breads_per_week, :phone
  config.sort_order = 'LOWER(first_name), LOWER(last_name)'

  # search filters on index page
  preserve_default_filters!
  remove_filter :credit_items, :messages, :orders, :order_items, :versions, :visits, \
    :created_at, :current_sign_in_at, :current_sign_in_ip, :encrypted_password, \
    :last_sign_in_at, :last_sign_in_ip, :remember_created_at, :reset_password_sent_at, \
    :reset_password_token, :sign_in_count, :updated_at

  scope :all, default: true
  scope "Tuesday", :tuesday_pickup
  scope "Thursday", :thursday_pickup
  scope "Weekly", :must_order_weekly
  scope "Semi-weekly", :every_other_week
  scope :customers
  scope :owners
  scope :admin
  scope :no_weekly_email

  index do
    selectable_column
    column :first_name do |user|
      span user.first_name
      if user.is_admin?
        status_tag true, style: 'margin-left: 3px', label: 'admin'
      end
    end
    column :last_name
    column :email do |user|
      para auto_link user, user.email
      small user.additional_email
    end
    column :pickup do |user|
      status_tag !user.tuesday_pickup?, style: 'margin-left: 3px', label: user.pickup_day
    end
    column :breads_per_week
    column :phone do |user|
      number_to_phone(user.phone)
    end
    column :created_at
    column :updated_at
    actions
  end

  form do |f|
    inputs 'Details' do
      input :first_name
      input :last_name
      input :email
      input :additional_email
      input :phone
      input :tuesday_pickup
      input :breads_per_week
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
        div strong user.email
        small user.additional_email
      end
      row :phone do |user|
        number_to_phone(user.phone)
      end
      row :pickup do |user|
        status_tag !user.tuesday_pickup?, style: 'margin-left: 3px', label: user.pickup_day
      end
      row :breads_per_week
      row :send_weekly_email
      row :is_admin
      row :created_at
      row :updated_at      
    end

    panel "Credit Items" do
      h4 "Available credits: #{user.credits}"
      table_for user.credit_items do
        column :quantity
        column :memo
        column :created_at
        column :good_for_weeks
      end

      render partial: 'admin/credit_items/form'
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
