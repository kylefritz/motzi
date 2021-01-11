class SendHaventOrderedReminderJob < ApplicationJob

  def perform(*args)
    pickup_day = PickupDay.for_order_deadline_at(Time.zone.now)
    return unless pickup_day

    menu = pickup_day.menu
    return unless menu.current?

    return unless SendHaventOrderedReminderJob.time_for_reminder_email?(pickup_day.order_deadline_at)
    
    already_reminded = Set[*menu.messages.where(mailer: 'ReminderMailer#havent_ordered_email').pluck(:user_id)]
    already_ordered = Set[*menu.orders.pluck(:user_id)]

    User.subscribers.find_each do |user|
      next if already_reminded.include?(user.id)
      next if already_ordered.include?(user.id)

      ReminderMailer.with(user: user, menu: menu).havent_ordered_email.deliver_now
    end
  end

  def self.time_for_reminder_email?(deadline)
    reminder_start = deadline - Setting.reminder_hours.hours - 1.minute
    Time.zone.now.between?(reminder_start, deadline)
  end
end
