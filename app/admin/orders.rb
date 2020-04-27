ActiveAdmin.register Order do
  permit_params :feedback, :comments, :menu, :user
  includes :menu, :user, order_items: :item

  scope :all, default: true
  scope("current menu") { |scope| scope.where(menu_id: Setting.menu_id) }
  scope :with_comments
  scope :with_feedback

  preserve_default_filters!
  remove_filter :ahoy_visit, :versions, :order_items

  index do
    selectable_column
    column :menu
    column :user
    column :items do |order|
      # TODO: show item day, quantity
      render partial: 'admin/orders/order_items', locals: {order_items: order.order_items}
    end
    column :feedback
    column :comments
    column :created_at
    actions
  end

  show do |order|
    attributes_table do
      row :user
      row :menu
      row :feedback
      row :comments
      row :order_items do
        render partial: 'admin/orders/order_items', locals: {order_items: order.order_items}
      end
      row :pickup_day
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end
end
