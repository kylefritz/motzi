ActiveAdmin.register Order do
  permit_params :feedback, :comments, :menu, :user
  includes :menu, :user, order_items: :item

  scope :all, default: true
  scope("current menu") { |scope| scope.where(menu_id: Setting.menu_id) }
  scope :with_comments
  scope :with_feedback
  scope :skip
  scope :not_skip

  preserve_default_filters!
  remove_filter :ahoy_visit, :versions, :order_items

  index do
    selectable_column
    column :menu
    column :user
    column :items do |order|
      render partial: 'admin/orders/order', locals: {order: order}
    end
    column :feedback
    column :comments
    column :created_at
    actions defaults: false do |order|
      if order.menu_id == Setting.menu_id
        item "Update", current_menu_url(uid: order.user.hashid, ignoredeadline: true), target: "_blank", class: "member_link"
      else
        item "View", resource_path(order), class: "member_link"
        item "Edit", edit_resource_path(order), class: "member_link"
      end
      item "Delete", resource_path(order), method: :delete, data: { confirm: "Delete Order?" }, class: "member_link"
    end
  end

  show do
    attributes_table do
      row :user
      row :menu
      row :feedback
      row :comments
      row :order_items do |order|
        render partial: 'admin/orders/order', locals: {order: order}
      end
      row :pickup_day
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end
end
