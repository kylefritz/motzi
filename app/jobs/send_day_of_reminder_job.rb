class SendDayOfReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return if Time.zone.now.too_early?

    menu = Menu.current

    already_reminded = Set[*menu.messages.where(mailer: 'ReminderMailer#day_of_email').pluck(:user_id)]

    users_to_remind.map do |user|
      next if already_reminded.include?(user.id)
      
      order = user.order_for_menu(menu)

      if must_pickup?(order, user)
        ReminderMailer.with(user: user, menu: menu, order: order).day_of_email.deliver_now
      end
    end
  end

  private

  def must_pickup?(order, user)
    if order
      # if there's an order, only remind if user hasn't skipped
      !order.skip?
    else
        # if there's no order, only remind if user must order weekly
      user.must_order_weekly?
    end
  end

  def users_to_remind
    return User.tuesday_pickup if Time.zone.now.tuesday_pickup?
    return User.thursday_pickup if Time.zone.now.thursday_pickup?

    []
  end
end
