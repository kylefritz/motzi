class SendDayOfReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return unless (7..11).include?(Time.zone.now.hour) # 7a-11a

    pickup_day_groups.each do |_, pickup_days|
      primary_pickup_day = select_primary_pickup_day(pickup_days)
      next unless primary_pickup_day

      send_reminders_for_day(primary_pickup_day, pickup_days)
    end
  end

  private
  def pickup_day_groups
    PickupDay.for_pickup_at(Time.zone.now).group_by(&:pickup_at)
  end

  def select_primary_pickup_day(pickup_days)
    pickup_days.min_by { |pickup_day| menu_priority(pickup_day.menu) }
  end

  def menu_priority(menu)
    [menu.is_special? ? 1 : 0, -menu.week_start.to_i]
  end

  def send_reminders_for_day(primary_pickup_day, pickup_days)
    menu = primary_pickup_day.menu
    already_reminded = Set[*menu.messages.where(mailer: "ReminderMailer#day_of_email", pickup_day: primary_pickup_day).pluck(:user_id)]

    menus = pickup_days.map(&:menu).uniq

    user_orders = Hash.new { |h, user_id| h[user_id] = { user: nil, menu_groups: [] } }

    menus.each do |candidate_menu|
      pickup_for_menu = pickup_days.find { |pd| pd.menu_id == candidate_menu.id }
      next unless pickup_for_menu

      candidate_menu.orders.includes(:user).find_each do |order|
        next if order.user_id.nil?
        next if already_reminded.include?(order.user_id)

        items = order.items_for_pickup(pickup_for_menu)
        next if items.empty?

        entry = user_orders[order.user_id]
        entry[:user] ||= order.user
        entry[:menu_groups] << {
          menu: candidate_menu,
          pickup_day: pickup_for_menu,
          order_items: items
        }
      end
    end

    num_reminded = 0

    user_orders.each_value do |payload|
      next if payload[:menu_groups].empty?

      user = payload[:user]
      next unless user

      begin
        ReminderMailer.with(
          user: user,
          menu: menu,
          menus: menus.sort_by { |m| menu_priority(m) },
          pickup_day: primary_pickup_day,
          order_items_by_menu: payload[:menu_groups].sort_by { |group| menu_priority(group[:menu]) }
        ).day_of_email.deliver_now
        already_reminded << user.id
        num_reminded += 1
      rescue => e
        Rails.logger.error "Failed to send reminder email to user #{user.id}: #{e.message}"
      end
    end

    if num_reminded > 0
      add_comment! menu, "Day Of reminder job: sent num_reminded=#{num_reminded}"
    end
  end
end
