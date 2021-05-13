include PriceHelper
ActiveAdmin.register Order do
  permit_params :comments, :menu, :user
  includes :menu, :user, order_items: [:item, :pickup_day]

  scope :all, default: true
  scope("current menu") { |scope| scope.where(menu_id: Setting.menu_id) }
  scope :subscriber
  scope :marketplace
  scope :with_comments
  scope :skip
  scope :not_skip

  filter :user_id_equals
  filter :comments
  filter :menu
  filter :items
  filter :stripe_charge_amount

  csv do
    column(:order_id) { |order| order.id }
    column :menu_id
    column :user_id
    column(:user_email) { |order| order.user.email_list }
    column(:items) { |order| order.item_list }
    column :stripe_charge_amount
    column :retail_price
    column :created_at
  end

  index do
    selectable_column
    id_column
    column :menu
    column :user
    column :items do |order|
      render partial: 'admin/orders/order', locals: {order: order}
    end
    column(:comments, &:comments_html)
    column :created_at
    column :paid do |order|
      if order.stripe_charge_amount.present?
        a number_to_currency(order.stripe_charge_amount), href: "https://dashboard.stripe.com/payments/#{order.stripe_charge_id}", target: '_blank', title: "via Stripe"
      else
        span "#{order.credits} cr"
      end
      if order.stripe_receipt_url.present?
        a "Receipt", href: order.stripe_receipt_url, target: '_blank', title: "Stripe Receipt"
      end
    end
    column :retail_price do |order|
      if order.stripe_charge_amount.present?
        div number_to_currency(order.retail_price), class: "text-right"
        price_diff(order.retail_price, order.stripe_charge_amount)
      end
    end
    actions defaults: false do |order|
      item "View", resource_path(order), class: "member_link"
      if order.menu_id == Setting.menu_id
        item "Update", current_menu_url(uid: order.user.hashid, ignoredeadline: true), target: "_blank", class: "member_link"
      else
        item "Edit", edit_resource_path(order), class: "member_link"
      end
      item "Delete", resource_path(order), method: :delete, data: { confirm: "Delete Order?" }, class: "member_link"
    end
  end

  show do
    attributes_table do
      row :user
      row :menu
      row :comments
      row :order_items do |order|
        render partial: 'admin/orders/order', locals: {order: order}
      end
      row :pickup_day
      row :stripe_receipt_url do |order|
         a order.stripe_receipt_url, href: order.stripe_receipt_url, target: '_blank', title: "Stripe Receipt"
      end
      row :stripe_charge_amount do |order|
        number_to_currency(order.stripe_charge_amount)
      end
      row :stripe_charge_id
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end
end
