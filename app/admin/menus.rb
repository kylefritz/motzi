ActiveAdmin.register Menu do
  permit_params :name, :bakers_note, :emailed_at

  show do |menu|
    attributes_table do
      row :name
      row :bakers_note
      row :menu_items do |menu_items|
                
        ul do 
          menu.menu_items.map do |menu_item|
            li "#{menu_item.item.name} #{menu_item.is_add_on? ? " (add-on)" : ""}"
          end
        end
      end
      row :created_at
      row :updated_at
      row :emailed_at do
        render 'publish', { menu: menu }
      end
    end

    active_admin_comments
  end

  #
  # action to make this menu "current" & email it to subscribers
  #
  member_action :finalize, method: :post do
    emails = resource.publish_to_subscribers!(current_admin_user.id)
    redirect_to collection_path, notice: "Menu emailed to #{emails.size} subscribers!"
  end

end
