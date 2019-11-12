require 'test_helper'

class SendDayOfReminderJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  def setup
    menus(:week2).make_current!
  end

  test "dont send on wrong day of week" do
    refute_reminders_emailed(:mon, '10:00 AM', 'dont send on mon')
    refute_reminders_emailed(:wed, '10:00 AM', 'dont send on wed')
  end

  test "Sends at right time" do
    assert_reminders_emailed(User.for_weekly_email.count, :tues, '7:00 AM', 'send on tues')
    assert_reminders_emailed(User.for_weekly_email.count, :thur, '7:00 AM', 'send on thurs')
    refute_reminders_emailed(:thur, '5:00 AM', 'dont send too early')
  end

  private
  def refute_reminders_emailed(day, time, msg)
    assert_reminders_emailed(0, day, time, msg)
  end

  def assert_reminders_emailed(num_emails, day, time, msg)
    days = {mon: '11-11',
        tues: '11-12',
        wed: '11-13',
        thur: '11-14'}
    assert days.include?(day), 'pick a known day'
    datetime_str = "2019-#{days[day]} #{time} EST"
    date_time = DateTime.parse(datetime_str)
    assert_difference('Ahoy::Message.count', num_emails, 'messages logged to ahoy') do
      assert_difference('ReminderMailer.deliveries.count', num_emails, msg) do
        perform_enqueued_jobs do
          Timecop.freeze(date_time) do
            SendDayOfReminderJob.perform_now
          end
        end
      end
    end

    assert_equal ReminderMailer.deliveries.count, Ahoy::Message.count, 'messages logged to ahoy'
  end
end
