class SendDayOfReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return unless (7..11).include?(Time.zone.now.hour) # 7a-11a

    PickupDay.for_pickup_at(Time.zone.now).each do |pickup_day|

      next unless pickup_day.menu.current?

      send_reminders_for_day(pickup_day)
    end
  end

  private
  def send_reminders_for_day(pickup_day)
    menu = pickup_day.menu

    already_reminded = Set[*menu.messages.where(mailer: "ReminderMailer#day_of_email", pickup_day: pickup_day).pluck(:user_id)]

    num_reminded = 0

    menu.orders.find_each do |order|
      next if already_reminded.include?(order.user_id)

      order_items_for_day = order.items_for_pickup(pickup_day)

      next if order_items_for_day.empty?

      begin
        ReminderMailer.with(user: order.user,
                            menu: menu,
                            pickup_day: pickup_day,
                            order_items: order_items_for_day
                           ).day_of_email.deliver_now
        num_reminded += 1
      rescue => e
        Rails.logger.error "Failed to send reminder email to user #{order.user_id}: #{e.message}"
      end
    end

    if num_reminded > 0
      add_comment! menu, "Day Of reminder job: sent num_reminded=#{num_reminded}"
    end
  end
end
