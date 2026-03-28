include PriceHelper
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1

  page_action :enqueue_queue_demo, method: :post do
    QueueDemoJob.perform_later(current_admin_user.id)
    redirect_to admin_dashboard_path, notice: "Queued demo job on the demo queue. Watch progress in Jobs."
  end

  page_action :send_test_emails, method: :post do
    EmailTestJob.perform_later
    redirect_to admin_dashboard_path, notice: "Test emails queued for #{User.kyle&.email}. Check letter_opener."
  end

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
            {
              type: name,
              ordered: orders.count,
              not_ordered: total - orders.count,
              total: total,
              credits: orders.includes(order_items: :item).sum(&:credits),
            }
          end

          subscribers = compute("Subscribers", User.receive_weekly_menu)
          mp_orders = Order.for_current_menu.marketplace.includes(order_items: :item)
          marketplace = {
            type: "Marketplace",
            ordered: mp_orders.count,
            total: mp_orders.count,
            credits: mp_orders.sum(&:credits),
          }
          rows = [subscribers, marketplace]
          if holiday_menu
            h_orders = Order.for_holiday_menu.includes(order_items: :item)
            rows << {type: "Holiday", not_ordered: "—", ordered: h_orders.count, total: h_orders.count, credits: h_orders.sum(&:credits)}
          end
          table_for rows, class: 'subscribers' do
            column :type
            column :not_ordered
            column("Orders") { |h| h[:ordered] }
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
        render 'admin/menus/what_to_bake', {menus: bake_menus}
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
          users = User.unscoped.receive_weekly_menu.where("created_at > ?", 2.weeks.ago).includes(:credit_items, orders: {order_items: :item}).order('created_at desc').limit(20)
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
        panel "Jobs & Tools" do
          div style: "display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 16px" do
            div style: "flex: 1; min-width: 180px; border: 1px solid #e8e8e8; border-radius: 4px; padding: 16px" do
              h4 "Queue Demo", style: "margin: 0 0 6px 0; font-size: 13px; text-transform: uppercase; letter-spacing: 0.05em; color: #666"
              para "20-second job to verify Solid Queue.", style: "font-size: 13px; color: #999; margin-bottom: 12px"
              text_node button_to("Queue Demo Job", "/admin/dashboard/enqueue_queue_demo", method: :post)
            end
            div style: "flex: 1; min-width: 180px; border: 1px solid #e8e8e8; border-radius: 4px; padding: 16px" do
              h4 "Test Emails", style: "margin: 0 0 6px 0; font-size: 13px; text-transform: uppercase; letter-spacing: 0.05em; color: #666"
              para "Send all email types to #{User.kyle&.email || 'kyle'}.", style: "font-size: 13px; color: #999; margin-bottom: 12px"
              text_node button_to("Send Test Emails", "/admin/dashboard/send_test_emails", method: :post)
            end
            div style: "flex: 1; min-width: 180px; border: 1px solid #e8e8e8; border-radius: 4px; padding: 16px; display: flex; flex-direction: column; justify-content: space-between" do
              h4 "Monitoring", style: "margin: 0 0 6px 0; font-size: 13px; text-transform: uppercase; letter-spacing: 0.05em; color: #666"
              div style: "display: flex; flex-direction: column; gap: 8px; margin-top: 8px" do
                a "Jobs Monitor", href: "/jobs", target: "_blank", style: "font-size: 14px"
                if Rails.env.development?
                  a "Letter Opener", href: "/letter_opener", target: "_blank", style: "font-size: 14px"
                  a "Mailer Previews", href: "/rails/mailers", target: "_blank", style: "font-size: 14px"
                  a "Routes", href: "/rails/info/routes", target: "_blank", style: "font-size: 14px"
                end
              end
            end
          end
        end

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
