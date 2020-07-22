class SendHaventOrderedReminderJob < ApplicationJob

  def perform(*args)
    return unless (19..23).include?(Time.zone.now.hour) # 7p-midnight
    return unless Time.zone.now.reminder_day?

    menu = Menu.current

    already_reminded = Set[*menu.messages.where(mailer: 'ReminderMailer#havent_ordered_email').pluck(:user_id)]
    already_ordered = Set[*menu.orders.pluck(:user_id)]

    User.subscribers.map do |user|
      next if already_reminded.include?(user.id)
      next if already_ordered.include?(user.id)

      ReminderMailer.with(user: user, menu: menu).havent_ordered_email.deliver_now
    end
  end
end
