require 'test_helper'

class SendDayOfReminderJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  def setup
    menus(:week2).make_current!
  end

  test "Sends emails" do
    assert_reminders_emailed(User.for_weekly_email.count) do
      SendDayOfReminderJob.perform_now
    end
  end

  def assert_reminders_emailed(num_emails, &block)
    perform_enqueued_jobs do
      assert_difference('ReminderMailer.deliveries.count', num_emails) do
        assert_difference('Ahoy::Message.count', num_emails) do
          block.call
        end
      end
    end
  end
end
