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

      
      def what_to_bake(orders, week_users)
        counts = Hash.new(0) # hash that defaults to 0 instead of nil
        orders.each do |order|
          order.items.each { |item| counts[item.name] += 1 }
        end
        num_must_order = week_users.must_order_weekly.count
        num_have_ordered = Order.for_current_menu.where(user_id: week_users.must_order_weekly.pluck(:id)).count
        num_havent_ordered_yet = num_must_order - num_have_ordered
        if num_havent_ordered_yet > 0
          counts[a("Baker's Choice*", {href: bakers_choice_admin_menus_path()})] = num_havent_ordered_yet
        end

        by_type = [
          {sub: "Weekly", ordered: num_have_ordered, total: num_must_order},
          {sub: "Every Other Week",
           ordered: Order.for_current_menu.where(user_id: week_users.every_other_week.pluck(:id)).count,
           total: week_users.every_other_week.count},
        ]
        table_for by_type, class: 'mt-0 subscribers' do
          column ("Subscriber Type") { |h| h[:sub] }
          column ("Ordered") { |h| h[:ordered] }
          column ("Not ordered") { |h| h[:total] - h[:ordered] }
          column ("Total") { |h| h[:total] }
        end

        table_for counts.keys.sort, class: 'mt-0 breads' do
          column ("Item") { |item| item }
          column ("Quantity") { |item| counts[item] }
        end
      end

      tues, thurs = Order.for_current_menu.partition(&:tuesday_pickup?)

      column id: 'what-to-bake-tues' do
        panel "Tuesday - What to bake" do
          a("Tuesday Pickup List", href: pickup_tues_admin_menus_path())
          what_to_bake(tues, User.tuesday_pickup)
        end
      end

      column id: 'what-to-bake-thurs' do
        panel "Thursday - What to bake" do
          a("Thursday Pickup List", href: pickup_thurs_admin_menus_path())
          what_to_bake(thurs, User.thursday_pickup)
        end
      end
    end


    columns do
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)

      column do
        panel "Orders with comments" do
          table_for menu.orders.includes(:user).with_comments do
            column ("comments") { |order| markdown.render(order.comments).html_safe }
            column ("user") { |order| order.user }
            column ("order") { |order| order }
          end
        end
      end

      column do
        
        panel "Orders with feedback" do
          table_for menu.orders.includes(:user).with_feedback do
            column ("feedback") { |order| markdown.render(order.feedback).html_safe }
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
          credits = get_user_credits(credit_items.map(&:user_id))
          table_for credit_items do
            column ("user") { |ci| ci.user }
            column ("balance") { |ci| credits[ci.user.id] }
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
