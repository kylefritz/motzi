ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do

    section do
      
    end

    columns do
      column do
        menu_name = Menu.current.name
        panel "What to bake - #{menu_name}" do
          tues_subs = User.for_weekly_email.where(is_first_half: true).count
          thurs_subs = User.for_weekly_email.where(is_first_half: true).count
          orders = Order.for_current_menu
          tues, thurs = orders.partition(&:is_first_half?)

          def summary(orders)
            counts = Hash.new(0) # hash that defaults to 0 instead of nil
            orders.each do |order|
              order.items.each { |item| counts[item.name] += 1 }
            end
            table_for counts.keys.sort do
              column ("Item") { |item| item }
              column ("Count") { |item| counts[item] }
            end
          end

          h4 "Tuesday - #{tues.count} / #{tues_subs} orders"
          summary(tues)

          h4 "Thursday - #{thurs.count} / #{thurs_subs} orders"
          summary(thurs)
          
          # ul do
          #   Post.recent(5).map do |post|
          #     li link_to(post.title, admin_post_path(post))
          #   end
          # end
        end
      end

      column do
        panel "Low credit balance" do
          h4 "TODO: credit balance"
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
        panel "Orders with comments" do
          h4 "TODO: orders with comments (for this week)"
          # ul do
          #   Post.recent(5).map do |post|
          #     li link_to(post.title, admin_post_path(post))
          #   end
          # end
        end
      end

      column do
        panel "Orders with feedback" do
          h4 "TODO: Recent feedback (for this week)"
          # ul do
          #   Post.recent(5).map do |post|
          #     li link_to(post.title, admin_post_path(post))
          #   end
          # end
        end
      end

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
