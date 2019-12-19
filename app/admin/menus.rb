ActiveAdmin.register Menu do
  permit_params :name, :bakers_note, :week_id
  includes menu_items: [:item]
  config.sort_order = 'LOWER(week_id) desc'

  actions :all, except: [:destroy] # deleting menus can orphan orders, etc

  scope("all") { |scope| scope }
  scope("current menu") { |scope| scope.where(id: Setting.menu_id) }
  scope("emailed") { |scope| scope.where("emailed_at is not null") }
  scope("not emailed") { |scope| scope.where("emailed_at is null") }
  
  # create big buttons on every menu page
  action_item :pickup_tues, except: [:index, :new] do
    link_to 'Tuesday Pickup List', pickup_tues_admin_menus_path()
  end
  action_item :pickup_thurs, except: [:index, :new] do
    link_to 'Thursday Pickup List', pickup_thurs_admin_menus_path()
  end
  action_item :preview, except: [:index, :new] do
    if params[:id].present?
      link_to 'Preview Menu', menu_path(params[:id]), target: "_blank"
    end
  end

  index do
    selectable_column()
    column :name do |menu|
      para do 
        strong auto_link menu
        if menu.current?
          status_tag true, style: 'margin-left: 3px', label: 'Current'
        end
      end
      small menu.bakers_note[0..140]
    end
    column :items do |menu|
      ul style: 'list-style: 	disc outside none !important; white-space: nowrap' do
        menu.menu_items.map do |menu_item|
          li "#{menu_item.item.name} #{menu_item.is_add_on? ? " (add-on)" : ""}"
        end
      end
    end
    column :week_id do |menu|
      para auto_link menu.week_id
      t = Time.zone.from_week_id(menu.week_id)
      small "#{t.strftime('%a %m/%d')}"
    end
    column :created_at
    column :updated_at
    column :emailed_at
    actions defaults: false do |menu|
      a "view", href: admin_menu_path(menu)
      a "edit", href: edit_admin_menu_path(menu)
      a "preview", href: "/menu/#{menu.id}", target: "_blank"
    end
  end

  form do |f|
    def week_options(resource_week)
      week_ids = (1..10).map {|i| (Time.zone.now + i.weeks).week_id }
      week_ids.push(resource_week) if resource_week.present?
      week_ids.uniq.sort.map do |week_id|
        t = Time.zone.from_week_id(week_id).strftime('%a %m/%d')
        ["#{week_id} starts #{t}", week_id]
      end
    end

    inputs do
      input :week_id, :as => :select, :collection => week_options(resource.week_id)
      input :name
      input :bakers_note
    end
    actions
  end

  show do |menu|
    attributes_table do
      row :week_id do
        span menu.week_id
        if menu.current?
          status_tag true, style: 'margin-left: 3px', label: 'Current'
        end
      end
      row :bakers_note do
        markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
        html = markdown.render(menu.bakers_note)
        html.html_safe
      end
      row :menu_items do
        render 'builder'
      end
      row :created_at
      row :updated_at
      row :emailed_at do
        render 'email', { menu: menu }
      end
    end

    active_admin_comments

    panel "Emails" do
      table_for menu.messages do
        column :mailer
        column :subject
        column :to do |email|
          div auto_link email.user, email.to
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
    num_emails = resource.publish_to_subscribers!
    notice = "Menu '#{resource.name}' was emailed to #{num_emails} subscribers"
    ActiveAdmin::Comment.create(body: notice,
                                namespace: 'admin',
                                resource: resource,
                                author: current_admin_user)

    redirect_to collection_path, notice: notice
  end

  collection_action :pickup_tues do
    @orders = Menu.current.orders.includes(:user).includes({order_items: :item}).select(&:tuesday_pickup?)
    @users_not_ordered = User.tuesday_pickup.where.not(id: @orders.pluck(:user_id))
    @page_title = "Tuesday Pickup List"
    render :pickup_list
  end

  collection_action :pickup_thurs do
    @orders = Menu.current.orders.includes(:user).includes({order_items: :item}).select(&:thursday_pickup?)
    @users_not_ordered = User.thursday_pickup.where.not(id: @orders.pluck(:user_id))
    @page_title = "Thursday Pickup List"
    render :pickup_list
  end

  collection_action :bakers_choice, method: [:get, :post] do
    if request.post?
      menu = Menu.current
      user = User.find(params[:user_id])
      item = Item.find(params[:item_id])
      order = Order.transaction do
        user.orders.create!(menu: menu, comments: "Baker's Choice").tap do |order|
          order.order_items.create!(item: item)
        end
      end

      @users = User.for_bakers_choice
      return render template: 'admin/users/index.json.jbuilder'
    end

    @users = User.for_bakers_choice
    gon.jbuilder template: 'app/views/admin/users/index.json.jbuilder', as: :havent_ordered

    @menu = Menu.current
    gon.jbuilder template: 'app/views/admin/menus/bakers_choice_menu.json.jbuilder', as: :menu

    render :bakers_choice
  end
end
