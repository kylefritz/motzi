require 'test_helper'

class SendWeeklyMenuJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  def setup
    menus(:week2).make_current!
  end

  test "send weekly menu email" do
    assert_menu_emailed(User.for_weekly_email.count, :sun, '10:00 AM')
    assert_menu_emailed(0, :sun, '10:01 AM', 'dont email people twice')
  end

  def assert_menu_emailed(num_emails, day, time, msg=nil)
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
        assert_difference('MenuMailer.deliveries.count', num_emails, msg) do
          perform_enqueued_jobs do
            SendWeeklyMenuJob.perform_now
          end
        end
      end
    end
    if num_emails > 0
      assert_equal 'MenuMailer#weekly_menu_email', Ahoy::Message.last.mailer, 'sent by right mailer action'
    end
  end
end
