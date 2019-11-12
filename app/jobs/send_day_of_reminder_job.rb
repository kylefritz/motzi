class SendDayOfReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    if !time_to_send? || too_early?
      return
    end

    User.for_weekly_email.map do |user|
      ReminderMailer.with(user: user, menu: Menu.current).day_of_email.deliver_later
    end
  end

  private
  def too_early?
    Time.zone.now.hour < 7 # before 7am
  end

  def time_to_send?
    today_is_first_half? || today_is_second_half?
  end

  def today_is_first_half?
    DateTime.now.wday == 4 # thurs
  end

  def today_is_second_half?
    DateTime.now.wday == 2 # tues
  end
end
