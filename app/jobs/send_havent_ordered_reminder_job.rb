class SendHaventOrderedReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    PickupDay.for_order_deadline_at(Time.zone.now).each do |pickup_day|
      send_reminders_for_day(pickup_day)
    end
  end

  private
  def send_reminders_for_day(pickup_day)
    menu = pickup_day.menu
    return unless menu.current?

    already_reminded = Set[*menu.messages.where(mailer: 'ReminderMailer#havent_ordered_email').pluck(:user_id)]
    already_ordered = Set[*menu.orders.pluck(:user_id)]

    num_reminded = 0

    User.subscribers.find_each do |user|
      next if already_reminded.include?(user.id)
      next if already_ordered.include?(user.id)

      begin
        ReminderMailer.with(user: user, menu: menu).havent_ordered_email.deliver_now
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
