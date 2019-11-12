class SendDayOfReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "pick up your bread"

    User.for_weekly_email.map do |user|
      ReminderMailer.with(user: user, menu: Menu.current).day_of_email.deliver_later
    end
  end

  private
  def valid_day?
    tues = 2
    thurs = 4
    [tues, thurs].include?(DateTime.now.wday)
  end
end
