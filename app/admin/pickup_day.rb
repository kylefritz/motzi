ActiveAdmin.register PickupDay do
  permit_params :menu_id, :pickup_at, :order_deadline_at
  menu false

  show title: proc { |pd| pd.day_str } do |pickup_day|
    date = pickup_day.pickup_at.to_date
    pickup_days = PickupDay.unscoped
      .where("pickup_at::date = ?", date)
      .order(:pickup_at)

    rows_hash = {}
    pickup_days.each do |pd|
      pd.menu.orders.not_skip.includes(:user, order_items: :item).each do |order|
        order_items = order.order_items.select { |oi| oi.pickup_day_id == pd.id }
        next if order_items.empty?
        rows_hash[order.user] ||= []
        rows_hash[order.user].concat(order_items)
      end
    end
    rows = rows_hash.sort_by { |user, _| user.sort_key }

    pickup_days.map(&:menu).uniq.each do |menu|
      para do
        text_node "Menu: "
        a menu.name, href: admin_menu_path(menu)
        if menu.holiday?
          status_tag 'Holiday', color: 'orange', style: 'margin-left: 6px; vertical-align: middle'
        end
      end
    end

    tabs do
      tab :orders do
        table_for rows, id: 'pickup-list' do
          column("Last Name") { |user, _| user.last_name.presence || user.email }
          column("First Name") { |user, _| user.first_name }
          column("Items") do |user, order_items|
            render partial: 'admin/orders/order_items', locals: {order_items: order_items, pickup_days: pickup_days}
          end
          column("Sign") { "" }
        end
      end

      tab :by_item do
        items_hash = {}
        rows.each do |user, order_items|
          order_items.each do |oi|
            item_name = oi.item.name
            items_hash[item_name] ||= []
            items_hash[item_name].push([user, oi.quantity])
          end
        end

        columns do
          items_hash.sort_by { |name, _| name }.each do |item_name, user_rows|
            users = Hash.new(0)
            user_rows.each { |user, qty| users[user.name.downcase] += qty }

            column do
              h3 item_name
              ol do
                users.sort_by { |name, _| name }.each do |name, qty|
                  li do
                    span name
                    strong("x#{qty}") if qty > 1
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
