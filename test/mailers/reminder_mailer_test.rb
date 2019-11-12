require 'test_helper'

class ReminderMailerTest < ActionMailer::TestCase
  test "day_of reminder" do
    user = users(:ljf)
    menu = menus(:week2)

    email = ReminderMailer.with(user: user, menu: menu).day_of_email
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email], email.to
    assert_equal 'Motzi Bread pick up today!', email.subject
    assert_in_both email, 'Reminder to come grab your bread today'
  end

  def assert_in_both(email, substring, msg=nil)
    assert_includes email.html_part.body.to_s, substring, msg
    assert_includes email.text_part.body.to_s, substring, msg
  end
end
