ActiveAdmin.register Order do
  permit_params :feedback, :comments, :menu, :user

  show do |order|
    attributes_table do
      row :user
      row :menu
      row :feedback
      row :comments
      row :order_items do |order_items|
                
        ul do 
          order.order_items.map do |order_items|
            li order_items.item.name
          end
        end
      end
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end
end