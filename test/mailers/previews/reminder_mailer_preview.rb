# Preview all emails at http://localhost:3000/rails/mailers/reminder_mailer
class ReminderMailerPreview < ApplicationMailerPreview
  def day_of_email
    user = User.last
    return missing("Need a User.") unless user

    menu = Menu.current
    return missing("Need a Menu.") unless menu

    order = Order.last
    return missing("Need an Order.") unless order

    ReminderMailer.with(menu: menu, user: user, order_items: order.order_items).day_of_email
  end

  def havent_ordered_email
    user = User.last
    return missing("Need a User.") unless user

    menu = Menu.current
    return missing("Need a Menu.") unless menu

    ReminderMailer.with(menu: menu, user: user).havent_ordered_email
  end
end
