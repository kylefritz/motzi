require 'test_helper'

class ReminderMailerTest < ActionMailer::TestCase
  def setup
    @user = users(:ljf)
    @menu = menus(:week2)
  end

  test "day_of email" do
    @email = ReminderMailer.with(user: @user, menu: @menu).day_of_email
    assert_emails(1) { @email.deliver_now }

    assert_equal [@user.email], @email.to
    assert_equal 'Motzi Bread pick up today!', @email.subject
    assert_in_email 'Reminder to come grab your bread today'
  end

  test "havent_ordered email" do
    @email = ReminderMailer.with(user: @user, menu: @menu).havent_ordered_email
    assert_emails(1) { @email.deliver_now }

    assert_equal [@user.email], @email.to
    assert_includes @email.subject, 'Make your selection soon'
    assert_in_email @menu.name
    assert_in_email 'Please place your order soon'
  end
  private

  def assert_in_email(substring, msg=nil)
    assert_includes @email.html_part.body.to_s, substring, msg
    assert_includes @email.text_part.body.to_s, substring, msg
  end
end
