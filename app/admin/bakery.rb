ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Bakery"

  content title: "Bakery" do
    menu = Menu.current

    columns do
      column do
        panel "Current Menu" do
          h4 a(menu.name, href: admin_menu_path(menu.id), class: 'bigger')
          ul do
            menu.menu_items.includes(:item).map do |menu_item|
              li "#{menu_item.item.name} #{menu_item.is_add_on? ? " (add-on)" : ""}"
            end
          end
        end
      end

      column do
        panel "Subscribers" do
          def compute(name, subs)
            total = subs.count
            orders = Order.for_current_menu.where(user_id: subs.pluck(:id))
            ordered = orders.not_skip.count
            skipped = orders.skip.count
            orders = Order.for_current_menu.where(user_id: subs.pluck(:id)).count
            {
              type: name,
              ordered: ordered,
              skipped: skipped,
              not_ordered: total - orders,
              total: total,
            }
          end

          customers = User.customers
          weekly = compute("Weekly", customers.must_order_weekly)
          by_type = [weekly, compute("Every Other Week", customers.every_other_week)]
          table_for by_type, class: 'subscribers' do
            column :type
            column :not_ordered
            column :ordered
            column :skipped
            column(:total) { |h| strong(h[:total]) }
          end

          if (num_bakers_choice = weekly[:not_ordered]) > 0
            para(a("Set Baker's Choice for #{num_bakers_choice} subscribers", {href: bakers_choice_admin_menus_path()}))
          end
        end
      end

      day1, day2 = Order.for_current_menu.includes(order_items: :item).flat_map(&:order_items).partition(&:day1_pickup?)

      column id: 'what-to-bake-day1' do
        panel "#{Setting.pickup_day1} - What to bake" do
          a("#{Setting.pickup_day1} Pickup List", href: pickup_day1_admin_menus_path())
          render 'admin/menus/what_to_bake', { order_items: day1 }
        end
      end

      column id: 'what-to-bake-day2' do
        panel "#{Setting.pickup_day2} - What to bake" do
          a("#{Setting.pickup_day2} Pickup List", href: pickup_day2_admin_menus_path())
          render 'admin/menus/what_to_bake', { order_items: day2}
        end
      end
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
    end # end columns

    columns do
      column do
        panel "Credit balance < 4" do
          low_credit_users = SqlQuery.new(:low_credit_users, balance: 4).execute
          users = Hash[User.find(low_credit_users.map {|r| r["user_id"]}).map{|u| [u.id, u] }]
          table_for low_credit_users do
            column ("user") { |r| users[r["user_id"]] }
            column ("balance") { |r| r["credit_balance"] }
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

      column do
        panel "New Users - last 2 weeks" do
          users = User.unscoped.customers.where("created_at > ?", 2.weeks.ago).includes(:credit_items, orders: {order_items: :item}).order('created_at desc').limit(20)
          credits = get_user_credits(users.map(&:id))
          table_for users do
            column ("user") { |u| u }
            column ("balance") { |u| credits[u.id] }
            column ("Created At") { |u| u.created_at }
          end
        end
      end

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
