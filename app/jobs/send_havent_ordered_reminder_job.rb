class SendHaventOrderedReminderJob < ApplicationJob

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

    User.subscribers.find_each do |user|
      next if already_reminded.include?(user.id)
      next if already_ordered.include?(user.id)

      ReminderMailer.with(user: user, menu: menu).havent_ordered_email.deliver_now
    end
  end
end
