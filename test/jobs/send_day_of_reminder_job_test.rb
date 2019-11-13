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
    refute_reminders_emailed(:thur, '5:00 AM', 'dont send too early')
    assert_reminders_emailed(User.first_half.count, :tues, '7:00 AM', 'send on tues')
    assert_reminders_emailed(User.second_half.count, :thur, '7:00 AM', 'send on thurs')
  end

  test "Doesnt send to users multiple times on same menu" do
    assert_reminders_emailed(User.first_half.count, :tues, '7:00 AM', 'send on tues')
    refute_reminders_emailed(:tues, '7:01 AM', 'dont send the second time')
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
    Timecop.freeze(date_time) do
      assert_difference('Ahoy::Message.count', num_emails, 'emails audited in ahoy') do
        assert_difference('ReminderMailer.deliveries.count', num_emails, msg) do
          perform_enqueued_jobs do
            SendDayOfReminderJob.perform_now
          end
        end
      end
    end

    if num_emails > 0
      assert_equal 'ReminderMailer#day_of_email', Ahoy::Message.last.mailer, 'sent by right mailer action'
    end
  end
end