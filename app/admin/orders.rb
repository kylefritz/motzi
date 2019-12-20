ActiveAdmin.register Order do
  permit_params :feedback, :comments, :menu, :user
  includes :menu, :user

  scope :all, default: true
  scope("current menu") { |scope| scope.where(menu_id: Setting.menu_id) }
  scope :with_comments
  scope :with_feedback

  show do |order|
    attributes_table do
      row :user
      row :menu
      row :feedback
      row :comments
      row :order_items do |order_items|
        render partial: 'admin/orders/items', locals: {items: order.items}
      end
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end
end
