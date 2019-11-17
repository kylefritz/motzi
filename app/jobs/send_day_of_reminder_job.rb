class SendDayOfReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return if Time.zone.now.too_early?

    menu = Menu.current

    already_reminded = Set[*menu.messages.where(mailer: 'ReminderMailer#day_of_email').pluck(:user_id)]

    # TODO: remind people who haven't ordered or skipped?
    users_to_remind.map do |user|
      next if already_reminded.include?(user.id)
      
      order = user.order_for_menu(menu)
      ReminderMailer.with(user: user, menu: menu, order: order).day_of_email.deliver_now
    end
  end

  private

  def users_to_remind
    return User.first_half if Time.zone.now.is_first_half?
    return User.second_half if Time.zone.now.is_second_half?

    []
  end
end
