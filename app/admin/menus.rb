ActiveAdmin.register Menu do
  permit_params :name, :bakers_note, :emailed_at
  
  # create big buttons on every menu page
  action_item :pickup_tues, except: [:index, :new] do
    link_to 'Tuesday Pickup List', pickup_tues_admin_menu_path(params[:id])
  end
  action_item :pickup_thurs, except: [:index, :new] do
    link_to 'Thursday Pickup List', pickup_thurs_admin_menu_path(params[:id])
  end

  show do |menu|
    attributes_table do
      row :bakers_note do
        markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
        html = markdown.render(menu.bakers_note)
        html.html_safe
      end
      row :menu_items do
                
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

  member_action :pickup_tues do
    @orders = Order.for_menu_id(resource.id).select(&:is_first_half?)
    @page_title = "Tuesday Pickup List"
    render :pickup_list
  end

  member_action :pickup_thurs do
    @orders = Order.for_menu_id(resource.id).reject(&:is_first_half?)
    @page_title = "Thursday Pickup List"
    render :pickup_list
  end
end
