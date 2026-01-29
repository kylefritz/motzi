class SendHaventOrderedReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    pickup_day_groups.each do |_, pickup_days|
      primary_pickup_day = select_primary_pickup_day(pickup_days)
      next unless primary_pickup_day

      send_reminders_for_day(primary_pickup_day, pickup_days)
    end
  end

  private

  def pickup_day_groups
    PickupDay.for_order_deadline_at(Time.zone.now).group_by(&:order_deadline_at)
  end

  def select_primary_pickup_day(pickup_days)
    pickup_days.min_by { |pickup_day| menu_priority(pickup_day.menu) }
  end

  def menu_priority(menu)
    [menu.is_special? ? 1 : 0, -menu.week_start.to_i]
  end

  def send_reminders_for_day(primary_pickup_day, pickup_days)
    menu = primary_pickup_day.menu
    already_reminded = Set[*menu.messages.where(mailer: 'ReminderMailer#havent_ordered_email', pickup_day: primary_pickup_day).pluck(:user_id)]

    menus = pickup_days.map(&:menu).uniq
    ordered_user_ids_by_menu = menus.index_by(&:id).transform_values do |menu_entry|
      Set[*menu_entry.orders.pluck(:user_id)]
    end

    num_reminded = 0

    User.subscribers.find_each do |user|
      next if already_reminded.include?(user.id)

      pending_menus = menus.reject do |candidate_menu|
        ordered_user_ids_by_menu[candidate_menu.id].include?(user.id)
      end
      next if pending_menus.empty?

      begin
        ReminderMailer.with(
          user: user,
          menu: menu,
          menus: pending_menus.sort_by { |m| menu_priority(m) },
          pickup_day: primary_pickup_day
        ).havent_ordered_email.deliver_now
        already_reminded << user.id
        num_reminded += 1
      rescue => e
        Rails.logger.error "Failed to send haven't ordered email to user #{user.id}: #{e.message}"
      end
    end

    if num_reminded > 0
      add_comment! menu, "Haven't Ordered reminder job: num_reminded=#{num_reminded}"
    end
  end
end
