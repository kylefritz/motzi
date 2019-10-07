ActiveAdmin.register Menu do
  permit_params :name, :bakers_note

  show do |menu|
    attributes_table do
      row :name
      row :bakers_note
      row :menu_items do |menu_items|
                
        ul do 
          menu.menu_items.map do |menu_item|
            li menu_item.item.name
          end
        end
      end
      row :created_at
      row :updated_at
    end

    render 'publish', { menu: menu }

    active_admin_comments
  end

  #
  # action to make this menu "current" & email it to subscribers
  #
  member_action :finalize, method: :post do
    resource.publish_to_subscribers!(current_admin_user.id)
    redirect_to resource_path, notice: "Menu emailed to subscribers!"
  end

end
