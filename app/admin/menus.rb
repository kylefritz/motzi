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

    active_admin_comments
  end

  controller do
    # This code is evaluated within the controller class

    def finalize
      menu = Menu.find(params[:id])
      menu.publish_to_subscribers!(current_admin_user.id)
      redirect_to [:admin, menu]
    end
  end

end
