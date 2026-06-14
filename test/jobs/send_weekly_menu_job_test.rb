require "test_helper"

class SendWeeklyMenuJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  def setup
    menus(:week2).make_current!
  end

  test "send weekly menu email" do
    assert_menu_emailed(User.receive_weekly_menu.count, :sun, "10:00 AM")
    assert_menu_emailed(0, :sun, "10:01 AM", "dont email people twice")
  end

  test "respects receive_weekly_menu preference" do
    users(:kyle).update!(receive_weekly_menu: false)
    expected = User.receive_weekly_menu.count
    assert_menu_emailed(expected, :sun, "10:00 AM")
  end

  def assert_menu_emailed(num_emails, day, time, msg = nil)
    travel_to_day_time(day, time) do
      assert_email_sent(num_emails) do
        assert_commented 2 do
          SendWeeklyMenuJob.perform_now
        end
      end
    end
    if num_emails > 0
      assert_equal "MenuMailer#weekly_menu_email", Ahoy::Message.last.mailer, "sent by right mailer action"
    end
  end
end
