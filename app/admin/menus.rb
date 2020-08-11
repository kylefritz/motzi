ActiveAdmin.register Menu do
  permit_params :name, :menu_note, :subscriber_note, :week_id, :day_of_note
  includes menu_items: [:item]
  config.sort_order = 'LOWER(week_id) desc'

  actions :all, except: [:destroy] # deleting menus can orphan orders, etc

  preserve_default_filters!
  remove_filter :menu_items, :orders, :messages, :versions

  scope :all, default: true
  scope("current menu") { |scope| scope.where(id: Setting.menu_id) }
  scope("emailed") { |scope| scope.where("emailed_at is not null") }
  scope("not emailed") { |scope| scope.where("emailed_at is null") }

  # create big buttons on every menu page
  action_item :pickup_day1, except: [:index, :new] do
    link_to "#{Setting.pickup_day1} Pickup List", pickup_day1_admin_menus_path()
  end
  action_item :pickup_day2, except: [:index, :new] do
    link_to "#{Setting.pickup_day2} Pickup List", pickup_day2_admin_menus_path()
  end
  action_item :preview, except: [:index, :new] do
    if params[:id].present?
      link_to 'Preview Menu', menu_path(params[:id]), target: "_blank"
    end
  end

  index do
    selectable_column
    column :name do |menu|
      div auto_link menu
      if menu.current?
        br
        status_tag true, style: 'margin-left: 3px', label: 'Current'
      end
    end
    column :items do |menu|
      ul style: 'list-style: 	disc outside none !important; white-space: nowrap' do
        menu.menu_items.map do |menu_item|
          li "#{menu_item.item.name}"
        end
      end
    end
    column :week_id do |menu|
      para auto_link menu.week_id
      t = Time.zone.from_week_id(menu.week_id)
      small "#{t.strftime('%a %m/%d')}"
    end
    column :stats do |menu|
      render 'admin/menus/sales', {menu: menu}
    end
    column :emailed_at
    actions defaults: false do |menu|
      item "View", admin_menu_path(menu), class: "member_link"
      item "Edit", edit_admin_menu_path(menu), class: "member_link"
      item "Preview", menu_path(menu), target: "_blank", class: "member_link"
    end
  end

  form do |f|
    def week_options(resource_week)
      week_ids = (-10..10).map {|i| (Time.zone.now + i.weeks).week_id } - Menu.pluck(:week_id)
      week_ids.push(resource_week) if resource_week.present?
      week_ids.uniq.sort.map do |week_id|
        t = Time.zone.from_week_id(week_id).strftime('%a %m/%d')
        ["#{week_id} starts #{t}", week_id]
      end
    end

    inputs do
      input :week_id, :as => :select, :collection => week_options(resource.week_id)
      input :name
      para style: 'margin-left: 20%; padding-left: 8px' do
        text_node "You can use "
        a("markdown", href: "https://wordpress.com/support/markdown-quick-reference/", target:"_blank" )
        text_node "to give the notes nice formatting!"
      end
      input :subscriber_note
      input :menu_note
      input :day_of_note, placeholder: 'Included in reminder emails sent out on pickup day'
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
      row :subscriber_note do
        menu.subscriber_note_html
      end
      row :menu_note do
        menu.menu_note_html
      end
      row :day_of_note do
        menu.day_of_note_html
      end
      row :menu_items do
        render 'builder'
      end
      row :send_test_email do
        button_to("Send yourself a test menu email", test_email_admin_menu_path(menu), method: :post)
      end
      row :created_at
      row :updated_at
      row :emailed_at do
        render 'email', { menu: menu }
      end
    end

    panel "Pay what you can" do
      # NB: this is an N+1 query but let's leave it for now because it's valuable
      render 'admin/menus/sales', {menu: menu}
    end

    active_admin_comments

    panel "Orders" do
      columns do
        day1, day2 = menu.item_counts

        column id: 'what-to-bake-day1' do
          panel "#{Setting.pickup_day1}" do
            render 'admin/menus/what_to_bake', { counts: day1, menu: menu }
          end
        end

        column id: 'what-to-bake-day2' do
          panel "#{Setting.pickup_day2}" do
            render 'admin/menus/what_to_bake', { counts: day2, menu: menu}
          end
        end
      end
    end

    panel "Emails" do
      table_for menu.messages.includes(:user) do
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

  # metaprogramming for day1_pickup, day2_pickup
  [1, 2].each do |day|
    day1_pickup = day == 1
    pickup_day = "day#{day}_pickup"

    collection_action "pickup_day#{day}" do
      orders = Menu.current.orders.not_skip.includes(:user).includes({order_items: :item})
      @rows = orders.map do |order|
        order_items = order.order_items.filter {|oi| oi.day1_pickup == day1_pickup}
        unless order_items.empty?
          [order.user, order_items]
        end
      end.compact

      @page_title = Setting.send("pickup_day#{day}")
      render :pickup_list
    end
  end

  member_action :item, method: :delete do
    menu = Menu.find(params[:id])
    MenuItem.where(menu: menu, item_id: params[:item_id]).destroy_all
    render json: {message: "deleted!"}
  end

  member_action :menu_items do
    @menu = resource
    render 'admin/menus/bakers_choice_menu.json.jbuilder'
  end

  collection_action :bakers_choice, method: [:get, :post] do
    if request.post?
      menu = Menu.current
      user = User.find(params[:user_id])
      item = Item.find(params[:item_id])
      day1_pickup = !(Setting.pickup_day2.casecmp?(params[:day])) # default to day 1
      order = Order.transaction do
        user.orders.create!(menu: menu, comments: Order::BAKERS_CHOICE).tap do |order|
          order.order_items.create!(item: item, day1_pickup: day1_pickup)
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

  member_action :test_email, method: :post do
    menu = resource
    MenuMailer.with(menu: menu, user: current_user).weekly_menu_email.deliver_now

    notice = "Menu '#{menu.name}' was emailed to #{current_user.email}"
    ActiveAdmin::Comment.create(body: notice,
                                namespace: "admin",
                                resource: menu,
                                author: current_admin_user)

    redirect_to resource_path, notice: notice
  end
end
