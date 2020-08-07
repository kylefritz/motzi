require 'test_helper'

class ConfirmationMailerTest < ActionMailer::TestCase
  test "order" do
    order = orders(:kyle_week1)
    Setting.pickup_instructions = "call when you get here"

    email = ConfirmationMailer.with(order: order).order_email
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [order.user.email], email.to
    assert_equal [order.user.additional_email], email.cc
    assert_includes email.subject, order.menu.name

    assert_in_both email, 'Pumpkin', 'items'
    assert_in_both email, Setting.pickup_day1_abbr, 'pickup_day1_abbr'
    assert_in_both email, "call when you get here", 'Setting.pickup_instructions'
  end

  test "credit_item" do
    credit_item = credit_items(:kyle)
    Setting.signup_email_text = "youre great"

    email = ConfirmationMailer.with(credit_item: credit_item).credit_email
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [credit_item.user.email], email.to
    assert_equal [credit_item.user.additional_email], email.cc
    assert_includes email.subject, Setting.shop.name

    assert_in_both email, "youre great", 'Setting.pickup_instructions'
  end

  private
  def assert_in_both(email, substring, msg=nil)
    assert_includes email.html_part.body.to_s, substring, msg
    assert_includes email.text_part.body.to_s, substring, msg
  end
end
