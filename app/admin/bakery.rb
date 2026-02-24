include PriceHelper
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1

  content title: "Hello friend" do
    if defined?(ReviewAppMailInterceptor) && ReviewAppMailInterceptor.active
      div class: 'flash flash_alert', style: 'margin-bottom: 16px' do
        span "Review app — emails are only delivered to admin users."
      end
    elsif Rails.env.development?
      div class: 'flash flash_alert', style: 'margin-bottom: 16px' do
        text_node "Local dev — emails open in browser via "
        a "letter_opener", href: "/letter_opener"
        text_node "."
      end
    end

    menu = Menu.current
    holiday_menu = Menu.current_holiday

    columns do
      column do
        panel "Menu" do
          h4 a(menu.name, href: admin_menu_path(menu.id), class: 'bigger')
          if holiday_menu
            h4 do
              a(holiday_menu.name, href: admin_menu_path(holiday_menu.id), class: 'bigger')
              status_tag 'Holiday', color: 'orange', class: 'holiday-tag'
            end
          end
        end
        panel "Orders" do
          def compute(name, subs)
            total = subs.count
            orders = Order.for_current_menu.where(user_id: subs.pluck(:id))
            ordered = orders.not_skip
            skipped = orders.skip.count
            num_orders = orders.count
            {
              type: name,
              ordered: ordered.count,
              skipped: skipped,
              not_ordered: total - num_orders,
              total: total,
              credits: ordered.includes(order_items: :item).sum(&:credits),
            }
          end

          subscribers = compute("Subscribers", User.subscribers)
          mp_orders = Order.for_current_menu.marketplace.not_skip.includes(order_items: :item)
          marketplace = {
            type: "Marketplace",
            ordered: mp_orders.count,
            total: mp_orders.count,
            credits: mp_orders.sum(&:credits),
          }
          rows = [subscribers, marketplace]
          if holiday_menu
            h_orders = Order.for_holiday_menu.not_skip.includes(order_items: :item)
            rows << {type: "Holiday", not_ordered: "—", skipped: "—", ordered: h_orders.count, total: h_orders.count, credits: h_orders.sum(&:credits)}
          end
          table_for rows, class: 'subscribers' do
            column :type
            column :not_ordered
            column("Orders") { |h| h[:ordered] }
            column("Skip") { |h| h[:skipped] }
            column("Credits used") { |h| h[:credits] }
            column(:total) { |h| strong(h[:total]) }
          end
        end

        panel "Sales" do
          render 'admin/menus/sales', {menu: menu}
          if holiday_menu
            h4 do
              text_node holiday_menu.name
              status_tag 'Holiday', color: 'orange', class: 'holiday-tag'
            end
            render 'admin/menus/sales', {menu: holiday_menu}
          end
        end

      end
      column span: 3 do
        bake_menus = [menu, holiday_menu].compact
        render 'admin/menus/what_to_bake_combined', {menus: bake_menus}
      end
    end


    columns do
      column do
        panel "New Credits - last 2 weeks" do
          credit_items = CreditItem.order('id desc').where("created_at > ?", 2.weeks.ago).includes(:user).limit(20)
          table_for credit_items do
            column ("user") { |ci| ci.user }
            column ("Amount") { |ci| ci.quantity }
            column ("Credit Added At") { |ci| ci.created_at }
          end
        end
      end

      column do
        panel "Credit balance < 4" do
          low_credit_users = SqlQuery.new(:low_credit_users, balance: 4, ordered_within_days: 30).execute
          users = Hash[User.find(low_credit_users.map {|r| r["user_id"]}).map{|u| [u.id, u] }]
          para "Subscribers with low credit balance who ordered in the last 30 days.", style: "color: #888; font-size: 0.85em; margin-bottom: 8px"
          table_for low_credit_users do
            column ("user") { |r| users[r["user_id"]] }
            column ("balance") { |r| r["credit_balance"] }
            column ("menu") { |r| r["last_menu_name"] }
          end
        end
      end
    end

    def get_user_credits(users_ids)
      if users_ids.empty?
        return {}
      end
      # can't send 0 users_ids to :user_credits
      rows = SqlQuery.new(:user_credits, user_ids: users_ids).execute
      Hash[rows.map {|r| [r["user_id"], r["credit_balance"]]} ]
    end

    columns do
      column do
        panel "Special Requests" do
          table_for menu.orders.includes(:user).with_comments do
            column ("comments") { |order| order.comments_html }
            column ("user") { |order| order.user }
            column ("order") { |order| order }
          end
        end
      end

      column do
        panel "New Users - last 2 weeks" do
          users = User.unscoped.subscribers.where("created_at > ?", 2.weeks.ago).includes(:credit_items, orders: {order_items: :item}).order('created_at desc').limit(20)
          credits = get_user_credits(users.map(&:id))
          table_for users do
            column ("user") { |u| u }
            column ("balance") { |u| credits[u.id] }
            column ("Created At") { |u| u.created_at }
          end
        end
      end

      column do
        panel "New Opt-In - last 2 weeks" do
          users = User.opt_in.where("created_at > ?", 2.weeks.ago).order('created_at desc').limit(20)
          table_for users do
            column ("user") { |u| u }
            column ("Created At") { |u| u.created_at }
          end
        end
      end
    end


    columns do
      column do
        panel "Recently updated content" do
          versions = PaperTrail::Version.order('id desc').limit(20).includes(:item)
          users = Hash[User.find(versions.map(&:whodunnit)).map{|u| [u.id.to_s, u] }]
          table_for versions do
            column ("Version") { |v| link_to(v.id, admin_version_path(v.id)) }
            column ("Object") { |v| v.item }
            column ("Type") { |v| v.item_type.underscore.humanize }
            column ("Modified at") { |v| v.created_at }
            column ("User") do |v|
              users[v.whodunnit]&.name.presence || "whodunnit: \"#{v.whodunnit}\""
            end
          end
        end
      end
    end # end columns

  end # content
end
