class SendDayOfReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return if Time.zone.now.too_early?

    menu = Menu.current

    already_reminded = Set[*menu.messages.where(mailer: 'ReminderMailer#day_of_email').pluck(:user_id)]

    # TODO: don't remind people who have skipped?
    users_to_remind.map do |user|
      next if already_reminded.include?(user.id)
      
      order = user.order_for_menu(menu)
      ReminderMailer.with(user: user, menu: menu, order: order).day_of_email.deliver_now
    end
  end

  private

  def users_to_remind
    return User.tuesday_pickup if Time.zone.now.tuesday_pickup?
    return User.thursday_pickup if Time.zone.now.thursday_pickup?

    []
  end
end
