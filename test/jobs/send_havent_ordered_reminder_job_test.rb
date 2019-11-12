require 'test_helper'

class SendHaventOrderedReminderJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  def setup
    menus(:week2).make_current!
    @user_ids = Set[*User.for_weekly_email.pluck(:id)]
    @user_ids_ordered = Set[*Menu.current.orders.pluck(:user_id)]
    @user_ids_to_remind = @user_ids - @user_ids_ordered
    @num_to_remind = @user_ids_to_remind.size
  end

  test "dont send on wrong day of week" do
    refute_reminders_emailed(:mon, '8:00 PM', 'dont send on mon')
    refute_reminders_emailed(:wed, '8:00 PM', 'dont send on wed')
  end

  test "Sends to users who havent ordered, at right time" do
    refute_reminders_emailed(:sun, '5:00 PM', 'dont send too early')
    assert_reminders_emailed(@num_to_remind, :sun, '7:00 PM', 'send on sunday night')
    just_messaged = Set[*Menu.current.messages.where(mailer: 'ReminderMailer#havent_ordered_email').pluck(:user_id)]
    assert_equal @user_ids_to_remind, just_messaged, 'we sent messages to who we wanted to'
  end

  test "Doesnt send to users multiple times on same menu" do
    assert_reminders_emailed(@num_to_remind, :sun, '7:00 PM', 'send on sunday night')
    refute_reminders_emailed(:sun, '7:01 PM', 'dont send the second time')
  end

  private
  def refute_reminders_emailed(day, time, msg)
    assert_reminders_emailed(0, day, time, msg)
  end

  def assert_reminders_emailed(num_emails, day, time, msg=nil)
    days = {
      sun: '11-10',
      mon: '11-11',
      tues: '11-12',
      wed: '11-13',
      thur: '11-14'
    }
    assert days.include?(day), 'pick a known day'

    datetime_str = "2019-#{days[day]} #{time} EST"
    date_time = DateTime.parse(datetime_str)

    Timecop.freeze(date_time) do
      assert_difference('Ahoy::Message.count', num_emails, 'emails audited in ahoy') do
        assert_difference('ReminderMailer.deliveries.count', num_emails, msg) do
          perform_enqueued_jobs do
            SendHaventOrderedReminderJob.perform_now
          end
        end
      end
    end
    if num_emails > 0
      assert_equal 'ReminderMailer#havent_ordered_email', Ahoy::Message.last.mailer, 'sent by right mailer action'
    end
  end
end
