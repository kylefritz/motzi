# Preview all emails at http://localhost:3000/rails/mailers/reminder_mailer
class ReminderMailerPreview < ActionMailer::Preview
  def day_of_email
    menu = Menu.current
    user = User.last
    ReminderMailer.with(menu: menu, user: user).day_of_email
  end
end
