class SendDayOfReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return unless (7..11).include?(Time.zone.now.hour) # 7a-11a

    if Time.zone.now.day1_pickup?
      send_reminders_for_day(true)
    end

    if Time.zone.now.day2_pickup?
      send_reminders_for_day(false)
    end
  end

  def send_reminders_for_day(day1_pickup)
    menu = Menu.for_current_week_id
    return if menu.nil?

    mailer = "day_of_email_day#{day1_pickup ? 1 : 2}"
    already_reminded = Set[*menu.messages.where(mailer: "ReminderMailer##{mailer}").pluck(:user_id)]

    menu.orders.find_each do |order|
      next if already_reminded.include?(order.user_id)

      order_items_for_day = order.order_items.send(day1_pickup ? :day1_pickup : :day2_pickup)

      next if order_items_for_day.empty?

      ReminderMailer.with(user: order.user, menu: menu, order_items: order_items_for_day).send(mailer).deliver_now
    end
  end
end
