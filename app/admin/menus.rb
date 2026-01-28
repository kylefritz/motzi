ActiveAdmin.register Menu do
  permit_params :name, :menu_note, :subscriber_note, :week_id, :day_of_note
  includes :pickup_days, menu_items: [:item]
  config.sort_order = 'LOWER(week_id) desc'

  actions :all, except: [:destroy] # deleting menus can orphan orders, etc

  filter :items
  filter :name
  filter :subscriber_note
  filter :week_id
  filter :menu_note
  filter :day_of_note

  scope :all, default: true
  scope("current menu") { |scope| scope.where(id: Setting.menu_id) }
  scope("emailed") { |scope| scope.where("emailed_at is not null") }
  scope("not emailed") { |scope| scope.where("emailed_at is null") }

  # create big buttons on every menu page
  action_item :preview, except: [:index, :new] do
    if params[:id].present?
      link_to 'Preview Menu', menu_path(params[:id]), target: "_blank"
    end
  end

  index do
    id_column
    column :name do |menu|
      div auto_link menu
      if menu.current?
        br
        status_tag true, style: 'margin-left: 3px', label: 'Current'
      end
    end
    column :items do |menu|
      ul style: 'list-style: 	disc outside none !important; white-space: nowrap' do
        menu.sorted_menu_items.map do |menu_item|
          li menu_item.item.name
        end
      end
    end
    column :week_id do |menu|
      para auto_link menu.week_id
      t = Time.zone.from_week_id(menu.week_id)
      small "#{t.strftime('%a %m/%d')}"
    end
    column :stats do |menu|
      if menu.emailed_at.blank? || menu.emailed_at > 6.weeks.ago
        render 'admin/menus/sales', {menu: menu}
      else
        span "Sales stats "
        a("in menu details", href: admin_menu_path(menu))
      end
    end
    column :emailed_at
    column :pickup_days do |menu|
      ul style: 'list-style: 	disc outside none !important; white-space: nowrap' do
        menu.pickup_days.map do |pickup_day|
          li a(pickup_day.name_abbr, href: admin_pickup_day_path(pickup_day))
        end
      end
    end
    actions defaults: false do |menu|
      item "View", admin_menu_path(menu), class: "member_link"
      item "Edit", edit_admin_menu_path(menu), class: "member_link"
      item "Preview", menu_path(menu), target: "_blank", class: "member_link"
    end
  end

  form do |f|
    def week_options(menu_week_id)
      week_ids = (-10..10).map {|i| (Time.zone.now + i.weeks).week_id } - Menu.pluck(:week_id)
      week_ids.push(menu_week_id) if menu_week_id.present?
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
      row :sales do
        render 'admin/menus/sales', {menu: menu}
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
      render 'admin/menus/what_to_bake', {menu: menu}
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

  member_action :test_email, method: :post do
    menu = resource
    MenuMailer.with(menu: menu, user: current_user).weekly_menu_email.deliver_later

    notice = "Menu '#{menu.name}' was emailed to #{current_user.email}"
    ActiveAdmin::Comment.create(body: notice,
                                namespace: "admin",
                                resource: menu,
                                author: current_admin_user)

    redirect_to resource_path, notice: notice
  end

  member_action :copy_from, method: :post do
    @menu = resource
    original_menu = Menu.find(params[:original_menu_id])

    @menu.copy_from(
      original_menu,
      copy_subscriber_note: params[:copy_subscriber_note] == "1",
      copy_menu_note: params[:copy_menu_note] == "1",
      copy_day_of_note: params[:copy_day_of_note] == "1"
    )

    notice = "Copied from menu #{params[:original_menu_id]}"
    ActiveAdmin::Comment.create(body: notice,
                                namespace: "admin",
                                resource: @menu,
                                author: current_admin_user)

    redirect_to resource_path, notice: notice
  end

  #
  # menu builder actions, could be own controller...
  #
  member_action :menu_builder do
    @menu = resource
    render 'admin/menus/menu_builder', formats: [:json]
  end

  member_action :item, method: :post do
    @menu = Menu.find(params[:id])
    Menu.transaction do 
      mi = @menu.menu_items.create!(
        item_id: params[:item_id],
        subscriber: params[:subscriber],
        marketplace: params[:marketplace]
      )

      params[:pickup_day_ids].each do |pickup_day_id|
        mi.menu_item_pickup_days.create!(pickup_day_id: pickup_day_id)
      end
    end

    render 'admin/menus/menu_builder', formats: [:json]
  end

  # TODO: should use DELETE instead of POST but axios doesn't send body
  # https://blog.liplex.de/send-body-with-axios-delete-request/
  member_action :remove_menu_item_pickup_day, method: :post do
    mipd = MenuItemPickupDay.find_by(menu_item_id: params[:menu_item_id], pickup_day_id: params[:pickup_day_id])
    mipd.destroy!

    @menu = MenuItem.find(params[:menu_item_id]).menu
    render 'admin/menus/menu_builder', formats: [:json]
  end

  member_action :remove_item, method: :post do
    @menu = Menu.find(params[:id])
    MenuItem.where(menu: @menu, item_id: params[:item_id]).destroy_all
    
    render 'admin/menus/menu_builder', formats: [:json]
  end

  member_action :remove_items, method: :post do
    @menu = Menu.find(params[:id])
    MenuItem.where(menu: @menu).delete_all

    render 'admin/menus/menu_builder', formats: [:json]
  end
end
