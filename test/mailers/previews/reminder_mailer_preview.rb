# Preview all emails at http://localhost:3000/rails/mailers/reminder_mailer
class ReminderMailerPreview < ActionMailer::Preview
  def day_of_email
    order_items = Order.last.order_items
    menu = Menu.current
    user = User.last
    ReminderMailer.with(menu: menu, user: user, order_items: order_items).day_of_email
  end

  def havent_ordered_email
    menu = Menu.current
    user = User.last
    ReminderMailer.with(menu: menu, user: user).havent_ordered_email
  end
end
