ActiveAdmin.register Order do
  permit_params :feedback, :comments, :menu, :user

  scope("all") { |scope| scope }
  scope("current menu") { |scope| scope.where(menu_id: Setting.menu_id) }

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