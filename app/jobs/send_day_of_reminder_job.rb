class SendDayOfReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return if Time.zone.now.too_early?
    if Time.zone.now.day1_pickup?
      send_reminders_for_day(true)
    end

    if Time.zone.now.day2_pickup?
      send_reminders_for_day(false)
    end
  end

  def send_reminders_for_day(day1_pickup)
    mailer = "day_of_email_day#{day1_pickup ? 1 : 2}"
    menu = Menu.current

    already_reminded = Set[*menu.messages.where(mailer: "ReminderMailer##{mailer}").pluck(:user_id)]

    Menu.current.orders.map do |order|
      next if already_reminded.include?(order.user_id)

      order_items_for_day = order.order_items.filter {|oi| oi.day1_pickup == day1_pickup}

      next if order_items_for_day.empty?

      ReminderMailer.with(user: order.user, menu: menu, order_items: order_items_for_day).send(mailer).deliver_now
    end
  end
end
