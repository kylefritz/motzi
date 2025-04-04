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

    num_to_remind = User.subscribers.count - already_reminded.count - already_ordered.count
    add_comment! menu, "SendHaventOrderedReminderJob: Starting to queue #{num_to_remind} reminder emails for menu #{menu.id}"

    User.subscribers.find_each do |user|
      next if already_reminded.include?(user.id)
      next if already_ordered.include?(user.id)

      begin
        ReminderMailer.with(user: user, menu: menu).havent_ordered_email.deliver_now
      rescue => e
        Rails.logger.error "Failed to send havent ordered email to user #{user.id}: #{e.message}"
      end
    end
  end
end
