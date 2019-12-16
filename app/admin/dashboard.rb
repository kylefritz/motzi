ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    menu = Menu.current

    columns do
      column do
        panel "Current Menu - #{menu.name}" do
          h4 a(menu.name, href: admin_menu_path(menu.id), class: 'bigger')
          ul do 
            menu.menu_items.map do |menu_item|
              li "#{menu_item.item.name} #{menu_item.is_add_on? ? " (add-on)" : ""}"
            end
          end
        end
      end

      
      def what_to_bake(orders, num_subs, href)
        counts = Hash.new(0) # hash that defaults to 0 instead of nil
        orders.each do |order|
          order.items.each { |item| counts[item.name] += 1 }
        end

        h4 a("#{orders.count} / #{num_subs} have ordered", {href: href}), class: 'mb-0'
        table_for counts.keys.sort do
          column ("Item") { |item| item }
          column ("Count") { |item| counts[item] }
        end
      end

      tues, thurs = Order.for_current_menu.partition(&:is_first_half?)

      column id: 'what-to-bake-tues' do
        panel "Tuesday - What to bake" do
          what_to_bake(tues, User.first_half.count, pickup_tues_admin_menu_path(menu.id))
        end
      end

      column id: 'what-to-bake-thurs' do
        panel "Thursday - What to bake" do
          what_to_bake(thurs, User.second_half.count, pickup_thurs_admin_menu_path(menu.id))
        end
      end
    end


    columns do

      column do
        panel "Orders with comments" do
          table_for menu.orders.where("comments is not null") do
            column ("comments") { |order| order.comments }
            column ("order") { |order| order }
            column ("user") { |order| order.user }
          end
        end
      end

      column do
        panel "Orders with feedback" do
          table_for menu.orders.where("feedback is not null") do
            column ("feedback") { |order| order.feedback }
            column ("order") { |order| order }
            column ("user") { |order| order.user }
          end
        end
      end

      
    end # end columns
    
    columns do
      column do
        panel "Credit balance < 4" do
          low_credit_users = SqlQuery.new(:low_credit_users, balance: 4).execute
          table_for low_credit_users do
            column ("user") { |r| User.find(r["user_id"]) }
            column ("balance") { |r| r["credit_balance"] }
          end
        end
      end

      column do
        panel "New subscribers" do
          h4 "TODO: subscribers"
        end
      end

      column do
        panel "Recently renewed" do
          h4 "TODO: Recently renewed"
        end
      end
    end


    columns do
      column do
        panel "Recently updated content" do
          table_for PaperTrail::Version.order('id desc').limit(20) do # Use PaperTrail::Version if this throws an error
            column ("Object") { |v| v.item }
            # column ("Item") { |v| link_to v.item, [:admin, v.item] } # Uncomment to display as link
            column ("Type") { |v| v.item_type.underscore.humanize }
            column ("Modified at") { |v| v.created_at.to_s :long }
            column ("User") do |v|
              User.find_by(id: v.whodunnit)&.first_name.presence || "whodunnit: '#{v.whodunnit}'"
            end
          end
        end
      end
    end # end columns

  end # content
end
