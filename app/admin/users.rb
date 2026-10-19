ActiveAdmin.register User do
  menu priority: 5
  permit_params :first_name, :last_name, :email, :additional_email, :is_admin, \
    :receive_weekly_menu, :receive_havent_ordered_reminder, :receive_day_of_reminder, \
    :mailing_list, :phone, :password
  config.sort_order = "LOWER(first_name), LOWER(last_name)"

  filter :first_name
  filter :last_name
  filter :email
  filter :additional_email
  filter :phone
  filter :mailing_list
  filter :receive_weekly_menu
  filter :receive_havent_ordered_reminder
  filter :receive_day_of_reminder

  scope :all, default: true
  scope :receive_weekly_menu
  scope :receive_havent_ordered_reminder
  scope :receive_day_of_reminder
  scope :spam
  scope :owners
  scope :admin

  batch_action :destroy

  action_item :order, except: [ :index, :new ] do
    if params[:id].present?
      user = User.find(params[:id])
      link_to "Order for", current_menu_url(uid: user.hashid, ignoredeadline: true), target: "_blank"
    end
  end
  action_item :resend_menu, except: [ :index, :new ] do
    if params[:id].present?
      link_to("Resend menu email", resend_menu_admin_user_path(params[:id]), { method: :post, data: { confirm: "Resend menu email?" } })
    end
  end

  index do
    selectable_column
    id_column
    column :first_name do |user|
      span user.first_name
      if user.is_admin?
        status_tag true, style: "margin-left: 3px", label: "admin"
      end
    end
    column :last_name
    column :email do |user|
      para auto_link user, user.email
      small user.additional_email
    end
    column "Weekly Menu", :receive_weekly_menu
    column "Havent Ordered Reminder", :receive_havent_ordered_reminder
    column "Day Of Reminder", :receive_day_of_reminder
    column :phone do |user|
      number_to_phone(user.phone)
    end
    column :created_at
    column :updated_at
    actions do |user|
      item "Order", current_menu_url(uid: user.hashid, ignoredeadline: true), target: "_blank", class: "member_link", title: "Order for this user"
      item "Resend menu", resend_menu_admin_user_path(user), method: :post, data: { confirm: "Resend menu email?" }, class: "member_link"
    end
  end

  form do |f|
    inputs "Details" do
      input :first_name
      input :last_name
      input :email
      input :additional_email
      input :phone
      input :mailing_list
    end
    inputs "Email Preferences" do
      input :receive_weekly_menu
      input :receive_havent_ordered_reminder
      input :receive_day_of_reminder
    end
    inputs "Danger Zone" do
      input :password
      input :is_admin
    end
    actions
  end

  show do |user|
    panel "User Details" do
      attributes_table_for user do
        row :name do
          strong user.name
          status_tag "admin", class: "yes", style: "margin-left: 6px" if user.is_admin?
        end
        row :email do
          div user.email
          div small(user.additional_email) if user.additional_email.present?
        end
        row(:phone) { number_to_phone(user.phone) }
        row("Credits") { strong user.credits }
        row "Emails" do
          {
            "Weekly menu" => user.receive_weekly_menu?,
            "Haven't ordered reminder" => user.receive_havent_ordered_reminder?,
            "Day-of reminder" => user.receive_day_of_reminder?,
            "Mailing list" => user.mailing_list?
          }.map do |label, on|
            content_tag(:span, label, class: "status_tag #{on ? "yes" : "no"}", title: on ? "on" : "off", style: "margin-right: 4px")
          end.then { |tags| safe_join(tags) }
        end
        row "Orders" do
          last = user.orders.maximum(:created_at)
          text_node pluralize(user.orders.count, "order")
          text_node " · last #{time_ago_in_words(last)} ago" if last
        end
        row("Member since") { user.created_at.strftime("%b %-d, %Y") }
      end
    end

    panel "Orders" do
      table_for user.orders.includes(:menu, order_items: :item).order(created_at: :desc) do
        column "menu" do |order|
          auto_link order.menu
        end
        column :order do |order|
          auto_link order
        end
        column :items do |order|
          render partial: "admin/orders/order", locals: { order: order }
        end
        column :paid do |order|
          if order.stripe_charge_amount.present?
            a number_to_currency(order.stripe_charge_amount), href: "https://dashboard.stripe.com/payments/#{order.stripe_charge_id}", target: "_blank", title: "via Stripe"
          else
            span "credits"
          end
          if order.stripe_receipt_url.present?
            a "Receipt", href: order.stripe_receipt_url, target: "_blank", title: "Stripe Receipt"
          end
        end
        column "Credits used" do |order|
          order.credits unless order.stripe_charge_amount.present?
        end
        column :retail_price do |order|
          if order.stripe_charge_amount.present?
            div number_to_currency(order.retail_price), class: "text-right"
            price_diff(order.retail_price, order.stripe_charge_amount)
          end
        end
        column :comments
      end
    end

    panel "Credits" do
      h4 "Available credits: #{user.credits}"
      ledger = user.credit_ledger.reverse
      shown = params[:ledger] == "all" ? ledger : ledger.first(20)
      if shown.size < ledger.size
        para style: "margin: 0 0 8px" do
          text_node "Showing the #{shown.size} most recent entries. "
          a "Show all #{ledger.size} entries", href: admin_user_path(user, ledger: "all")
        end
      end
      table_for shown, class: "index_table credit-ledger" do
        column :when do |entry|
          entry.at.strftime("%a %-m/%-d/%y %-l:%M%P")
        end
        column :change do |entry|
          entry.change.positive? ? "+#{entry.change}" : entry.change.to_s
        end
        column :balance
        column :details do |entry|
          case entry.source
          when CreditItem
            text_node entry.source.memo.presence || (entry.change.negative? ? "Credits removed" : "Credits added")
          when Order
            text_node auto_link(entry.source, "Order ##{entry.source.id}")
            text_node " · "
            text_node auto_link(entry.source.menu)
            text_node " · #{entry.source.item_list}"
          end
        end
        column :by do |entry|
          if entry.by.nil?
            span(entry.source.try(:stripe_charge_id).present? ? "Stripe" : "—", class: "empty")
          elsif entry.by == user
            text_node "Customer"
          else
            auto_link(entry.by, entry.by.first_name.presence || entry.by.name)
          end
        end
      end

      render partial: "admin/credit_items/form"
    end

    panel "Emails" do
      table_for user.messages.order(sent_at: :desc) do
        column "menu" do |email|
          auto_link email.menu
        end
        column :sent_at
        column :opened_at
        column :clicked_at
        column :to
        column :subject
        column :mailer
      end
    end

    panel "Version History" do
      table_for user.versions.order(created_at: :desc) do
        column :created_at
        column :event
        column :whodunnit do |v|
          if v.whodunnit.present?
            admin = User.find_by(id: v.whodunnit)
            admin ? auto_link(admin, admin.name) : v.whodunnit
          end
        end
        column :changes do |v|
          if v.changeset.present?
            v.changeset.except("updated_at", "encrypted_password").map do |attr, (old_val, new_val)|
              "#{attr}: #{old_val.inspect} → #{new_val.inspect}"
            end.join(", ")
          end
        end
      end
    end

    active_admin_comments
  end

  member_action :resend_menu, method: :post do
    user = resource
    menu = Menu.current
    MenuMailer.with(menu: menu, user: user).weekly_menu_email.deliver_now

    notice = "Menu '#{menu.name}' was emailed to #{user.name}"
    ActiveAdmin::Comment.create(body: notice,
                                namespace: "admin",
                                resource: menu,
                                author: current_admin_user)

    redirect_to collection_path, notice: notice
  end


  controller do
    # only update a user's password if a new password is specified
    def update
      if params[:user][:password].blank?
        params[:user].delete("password")
      end
      super
    end

    # modify the destroy action to disallow deleting users who have orders
    def destroy
      if params[:id] == "batch_action"
        users = User.includes(:orders).where(id: params[:collection_selection])
        num_deleted = 0

        users.find_each do |user|
          if user.orders.empty?
            user.destroy!
            num_deleted += 1
          end
        end
        return redirect_to collection_path, notice: "Deleted #{num_deleted} users"
      end

      unless resource.orders.empty?
        return redirect_to collection_path, alert: "Only users without orders can be deleted"
      end

      resource.destroy!
      redirect_to collection_path, notice: "User '#{resource.name}' deleted"
    end
  end
end
