require 'test_helper'

class MenuMailerTest < ActionMailer::TestCase
  test "weekly_menu_email" do
    user = users(:kyle)
    menu = menus(:week2)

    email = MenuMailer.with(user: user, menu: menu).weekly_menu_email
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [user.email], email.to
    assert_equal [user.additional_email], email.cc
    assert_includes email.subject, menu.name
    assert_in_both email, 'Another great market yesterday', 'includes bakers note'
    assert_in_both email, 'You have 20 credits remaining', 'includes credits'
  end

  private
  def assert_in_both(email, substring, msg=nil)
    assert_includes email.html_part.body.to_s, substring, msg
    assert_includes email.text_part.body.to_s, substring, msg
  end
end
