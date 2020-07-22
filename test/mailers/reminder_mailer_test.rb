require 'test_helper'

class ReminderMailerTest < ActionMailer::TestCase
  include DeadlineHelper
  def setup
    @user = users(:ljf)
    @menu = menus(:week2)
  end

  test "day_of email with order" do
    @user = users(:kyle)
    @order = @user.order_for_menu(@menu)
    refute_nil @order
    @email = ReminderMailer.with(user: @user, menu: @menu, order_items: @order.order_items).day_of_email_day1
    assert_emails(1) { @email.deliver_now }

    assert_equal [@user.email], @email.to
    assert_equal 'Motzi Bread pick up today!', @email.subject
    assert_in_email 'Reminder to come grab your bread today'
    assert_in_email 'You ordered'
    assert_in_email 'Rye Five', 'item'
    assert_in_email 'Donuts', 'add-on'
    assert_in_email 'Bread is at the shop now!', 'day of note'
    assert_in_email 'credits remaining', 'includes credits'
  end

  test "day_of email without credits (marketplace)" do
    @user = users(:kyle)
    @user.update(subscriber: false)
    @order = @user.order_for_menu(@menu)

    @email = ReminderMailer.with(user: @user, menu: @menu, order_items: @order.order_items).day_of_email_day1
    assert_emails(1) { @email.deliver_now }

    refute_in_email 'credits remaining', 'doesnt show credits'
  end

  test "havent_ordered email" do
    @email = ReminderMailer.with(user: @user, menu: @menu).havent_ordered_email
    assert_emails(1) { @email.deliver_now }

    assert_equal [@user.email], @email.to
    assert_includes @email.subject, 'Make your selection soon'
    assert_in_email @menu.name
    assert_in_email day_to_order_by_text
  end
  private

  def assert_in_email(substring, msg=nil)
    assert_includes @email.html_part.body.to_s, substring, msg
    assert_includes @email.text_part.body.to_s, substring, msg
  end

  def refute_in_email(substring, msg=nil)
    refute_includes @email.html_part.body.to_s, substring, msg
    refute_includes @email.text_part.body.to_s, substring, msg
  end
end
