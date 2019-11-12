ActiveAdmin.register Menu do
  permit_params :name, :bakers_note
  includes menu_items: [:item]

  actions :all, except: [:destroy] # deleting menus can orphan orders, etc

  scope("all") { |scope| scope }
  scope("current menu") { |scope| scope.where(id: Setting.menu_id) }
  scope("emailed") { |scope| scope.where("emailed_at is not null") }
  scope("not emailed") { |scope| scope.where("emailed_at is null") }
  
  # create big buttons on every menu page
  action_item :pickup_tues, except: [:index, :new] do
    link_to 'Tuesday Pickup List', pickup_tues_admin_menu_path(params[:id])
  end
  action_item :pickup_thurs, except: [:index, :new] do
    link_to 'Thursday Pickup List', pickup_thurs_admin_menu_path(params[:id])
  end
  action_item :preview, except: [:index, :new] do
    link_to 'Preview Menu', menu_path(params[:id]), target: "_blank"
  end

  index do
    selectable_column()
    column :name do |menu|
      para strong auto_link menu
      small menu.bakers_note[0..140]
    end
    column :items do |menu|
      ul style: 'list-style: 	disc outside none !important; white-space: nowrap' do
        menu.menu_items.map do |menu_item|
          li "#{menu_item.item.name} #{menu_item.is_add_on? ? " (add-on)" : ""}"
        end
      end
    end
    column :created_at
    column :updated_at
    column :emailed_at
    actions defaults: false do |menu|
      a "edit", href: edit_admin_menu_path(menu)
      a "preview", href: "/menu/#{menu.id}", target: "_blank"
      a 'tues', href: pickup_tues_admin_menu_path(menu)
      a 'thurs', href: pickup_thurs_admin_menu_path(menu)
    end
  end

  show do |menu|
    attributes_table do
      row :bakers_note do
        markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
        html = markdown.render(menu.bakers_note)
        html.html_safe
      end
      row :menu_items do                
        # ul do 
        #   menu.menu_items.map do |menu_item|
        #     li "#{menu_item.item.name} #{menu_item.is_add_on? ? " (add-on)" : ""}"
        #   end
        # end
        render 'builder'
      end
      row :created_at
      row :updated_at
      row :emailed_at do
        render 'publish', { menu: menu }
      end
    end

    active_admin_comments

    panel "Emails" do
      table_for menu.messages do
        column :mailer
        column :subject
        column :to do |email|
          div auto_link email.to
        end
        column :user do |email|
          div auto_link email.user
        end
        column :sent_at
        column :opened_at
        column :clicked_at
      end
    end
  end

  #
  # action to make this menu "current" & email it to subscribers
  #
  member_action :email_menu, method: :post do
    emails = resource.publish_to_subscribers!
    notice = "Menu '#{resource.name}' was emailed to #{emails.size} subscribers"
    ActiveAdmin::Comment.create(body: notice,
                                namespace: 'admin',
                                resource: resource,
                                author: current_admin_user)

    redirect_to collection_path, notice: notice
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
