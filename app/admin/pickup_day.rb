ActiveAdmin.register PickupDay do
  permit_params :menu_id, :pickup_at, :order_deadline_at
  menu false

  show do |pickup_day|

    orders =  pickup_day.menu.orders.not_skip.includes(:user).includes({order_items: :item})
    rows = orders.map do |order|
      order_items = order.order_items.filter {|oi| oi.pickup_day == pickup_day}
      unless order_items.empty?
        [order.user, order_items]
      end
    end.compact

    tabs do

      tab :orders do
        table_for rows.sort_by {|user, _| user.sort_key }, id: 'pickup-list' do
          column ("Last Name") { |user, _| user.last_name.presence || user.email }
          column ("First Name") { |user, _| user.first_name }
          column ("Items") do |user, order_items|
            render partial: 'admin/orders/order_items', locals: {order_items: order_items, pickup_days: [pickup_day]}
          end
          column ("Sign") { "" }
        end
      end

      tab :by_item do
        columns do
          {}.tap do |items|
            rows.each do |user, order_items|
              order_items.each do |oi|
                item_name = oi.item.name
                unless items.key?(item_name)
                  items[item_name] = []
                end
                items[item_name].push([user, oi.quantity])
              end
            end
          end.entries.sort_by {|item,_| item}.map do |item, rows|
            users = Hash.new(0).tap do |counts|
              rows.each { |user, quantity| counts[user.name.downcase] += quantity }
            end

            column do
              h3 item
              ol do
                users.entries.sort_by {|user, _| user }.map do |user, quantity|
                  li do
                    span user
                    if quantity > 1
                      strong("x#{quantity}")
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

end
