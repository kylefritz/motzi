class SendHaventOrderedReminderJob < ApplicationJob

  def perform(*args)
    menu = Menu.for_current_week_id
    return if menu.nil?

    return unless SendHaventOrderedReminderJob.time_for_reminder_email?(menu)

    already_reminded = Set[*menu.messages.where(mailer: 'ReminderMailer#havent_ordered_email').pluck(:user_id)]
    already_ordered = Set[*menu.orders.pluck(:user_id)]

    User.subscribers.find_each do |user|
      next if already_reminded.include?(user.id)
      next if already_ordered.include?(user.id)

      ReminderMailer.with(user: user, menu: menu).havent_ordered_email.deliver_now
    end
  end

  def self.inside_reminder_window?(deadline)
    reminder_start = deadline - Setting.reminder_hours.hours - 1.minute
    Time.zone.now.between?(reminder_start, deadline)
  end

  def self.time_for_reminder_email?(menu)
    inside_reminder_window?(menu.day1_deadline) || inside_reminder_window?(menu.day2_deadline)
  end
end
