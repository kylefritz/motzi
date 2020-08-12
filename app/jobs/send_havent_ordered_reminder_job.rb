class SendHaventOrderedReminderJob < ApplicationJob

  def perform(*args)
    menu = Menu.current

    return unless inside_reminder_window?(menu.day1_deadline) || inside_reminder_window?(menu.day2_deadline)

    already_reminded = Set[*menu.messages.where(mailer: 'ReminderMailer#havent_ordered_email').pluck(:user_id)]
    already_ordered = Set[*menu.orders.pluck(:user_id)]

    User.subscribers.find_each do |user|
      next if already_reminded.include?(user.id)
      next if already_ordered.include?(user.id)

      ReminderMailer.with(user: user, menu: menu).havent_ordered_email.deliver_now
    end
  end

  def inside_reminder_window?(deadline)
    reminder_start = deadline - Setting.reminder_hours.to_f.hours
    Time.zone.now.between?(reminder_start, deadline)
  end
end
