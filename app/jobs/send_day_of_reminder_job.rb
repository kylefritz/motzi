class SendDayOfReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return if Time.zone.now.too_early?

    menu = Menu.current

    already_reminded = Set[*menu.messages.where(mailer: 'ReminderMailer#day_of_email').pluck(:user_id)]

    orders_to_remind.map do |order|
      next if already_reminded.include?(order.user_id)

      next if order.skip?

      ReminderMailer.with(user: order.user, menu: menu, order: order).day_of_email.deliver_now
    end
  end

  private

  def orders_to_remind
    # reminder users if they have an order for today
    return Menu.current.orders.day1_pickup if Time.zone.now.day1_pickup?
    return Menu.current.orders.day2_pickup if Time.zone.now.day2_pickup?

    []
  end
end
