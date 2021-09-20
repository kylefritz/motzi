ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :additional_email, :is_admin, \
    :subscriber, :opt_in, :breads_per_week, :phone, :password
  config.sort_order = 'LOWER(first_name), LOWER(last_name)'

  filter :first_name
  filter :last_name
  filter :email
  filter :additional_email
  filter :phone
  filter :opt_in

  scope :all, default: true
  scope :subscribers
  scope :nonsubscribers
  scope :spam
  scope :owners
  scope :admin

  batch_action :destroy

  controller do
    def update
      if params[:user][:password].blank?
        params[:user].delete("password")
      end
      super
    end
  end

  action_item :order, except: [:index, :new] do
    if params[:id].present?
      user = User.find(params[:id])
      link_to "Order for", current_menu_url(uid: user.hashid, ignoredeadline: true), target: "_blank"
    end
  end
  action_item :resend_menu, except: [:index, :new] do
    if params[:id].present?
      link_to("Resend menu email", resend_menu_admin_user_path(params[:id]), { method: :post, data: {confirm: "Resend menu email?"}})
    end
  end

  index do
    selectable_column
    id_column
    column :first_name do |user|
      span user.first_name
      if user.is_admin?
        status_tag true, style: 'margin-left: 3px', label: 'admin'
      end
    end
    column :last_name
    column :email do |user|
      para auto_link user, user.email
      small user.additional_email
    end
    column :subscriber
    column :phone do |user|
      number_to_phone(user.phone)
    end
    column :created_at
    column :updated_at
    actions do |user|
      item "Order", current_menu_url(uid: user.hashid, ignoredeadline: true), target: "_blank", class: "member_link", title: "Order for this user"
      item "Resend menu", resend_menu_admin_user_path(user), method: :post, data: {confirm: "Resend menu email?"}, class: "member_link"
    end
  end

  form do |f|
    inputs 'Details' do
      input :first_name
      input :last_name
      input :email
      input :additional_email
      input :phone
      input :breads_per_week
      input :opt_in
    end
    inputs 'Danger Zone' do
      input :password
      input :subscriber
      input :is_admin
    end
    actions
  end

  show do |user|

    panel "Orders" do
      table_for user.orders do
        column "menu" do |order|
          auto_link order.menu
        end
        column :order do |order|
          auto_link order
        end
        column :items do |order|
          render partial: 'admin/orders/order', locals: {order: order}
        end
        column :paid do |order|
          if order.stripe_charge_amount.present?
            a number_to_currency(order.stripe_charge_amount), href: "https://dashboard.stripe.com/payments/#{order.stripe_charge_id}", target: '_blank', title: "via Stripe"
          else
            span "#{order.credits} cr"
          end
          if order.stripe_receipt_url.present?
            a "Receipt", href: order.stripe_receipt_url, target: '_blank', title: "Stripe Receipt"
          end
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

    attributes_table do
      row :name
      row :email do |user|
        div strong user.email
        small user.additional_email
      end
      row :phone do |user|
        number_to_phone(user.phone)
      end
      row :breads_per_week
      row :subscriber
      row :is_admin
      row :created_at
      row :updated_at
    end

    panel "Credit Items" do
      h4 "Available credits: #{user.credits}"
      table_for user.credit_items do
        column :quantity
        column :memo
        column :created_at
        column :good_for_weeks
      end

      render partial: 'admin/credit_items/form'
    end

    panel "Emails" do
      table_for user.messages do
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

    active_admin_comments
  end

  member_action :resend_menu, method: :post do
    user = resource
    menu = Menu.current
    MenuMailer.with(menu: menu, user: user).weekly_menu_email.deliver_now

    notice = "Menu '#{menu.name}' was emailed to #{user.name}"
    ActiveAdmin::Comment.create(body: notice,
                                namespace: 'admin',
                                resource: menu,
                                author: current_admin_user)

    redirect_to collection_path, notice: notice
  end

  # modify the destroy action to disallow deleting users who have orders
  member_action :destroy, method: :post do
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
