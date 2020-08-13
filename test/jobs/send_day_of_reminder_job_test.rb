require 'test_helper'

class SendDayOfReminderJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  def setup
    menus(:week2).make_current!
    Menu.current.update!(week_id: "19w46") # match the time travel for this test
  end

  test "dont send on wrong day of week" do
    refute_reminders_emailed(:mon, '10:00 AM', 'dont send on mon')
    refute_reminders_emailed(:wed, '10:00 AM', 'dont send on wed')
  end

  test "Sends at right time" do
    refute_reminders_emailed(:tues, '5:00 AM', 'dont send too early')
    refute_reminders_emailed(:thurs, '5:00 AM', 'dont send too early')
    assert_reminders_emailed(Menu.current.order_items.day1_pickup.map(&:order_id).uniq.count, :tues, '7:00 AM', 'send on day1/tues')
    assert_reminders_emailed(Menu.current.order_items.day2_pickup.map(&:order_id).uniq.count, :thurs, '7:00 AM', 'send on day2/thurs; not to jess')
    refute_reminders_emailed(:tues, '1:00 PM', 'dont send too early')
    refute_reminders_emailed(:thurs, '1:00 PM', 'dont send too late')
  end

  test "wrong week_id" do
    Menu.current.update!(week_id: "19w44")
    refute_reminders_emailed(:tues, '7:00 AM', 'before, no menu: day1/tues')
    refute_reminders_emailed(:thurs, '7:00 AM', 'before, no menu: day2/thurs')

    Menu.current.update!(week_id: "19w47")
    refute_reminders_emailed(:tues, '7:00 AM', 'before, no menu: day1/tues')
    refute_reminders_emailed(:thurs, '7:00 AM', 'before, no menu: day2/thurs')
  end

  test "Sends according to pickup day settings" do
    Setting.pickup_day1 = "Thursday"
    Setting.pickup_day2 = "Saturday"

    assert_reminders_emailed(Menu.current.order_items.day1_pickup.map(&:order_id).uniq.count, :thurs, '7:00 AM', 'send on day1/thurs')
    assert_reminders_emailed(Menu.current.order_items.day2_pickup.map(&:order_id).uniq.count, :sat, '7:00 AM', 'send on day2/sat; not to jess')
  end

  test "includes all users who've ordered" do
    order_item(:jess, items(:classic))
    assert_reminders_emailed(Menu.current.order_items.day2_pickup.map(&:order_id).uniq.count, :thurs, '7:00 AM', 'sends to jess too')
  end

  test "weekly orders who skipped shouldn't get reminders" do
    Menu.current.order_items.day2_pickup.delete_all
    assert Menu.current.order_items.day2_pickup.map(&:order_id).uniq.empty?, 'cleared the orders'
    assert_reminders_emailed(0, :thurs, '7:00 AM', 'shouldnt send to laura since skipped')
  end

  test "Doesnt send to users multiple times on same menu" do
    assert_reminders_emailed(Menu.current.order_items.day1_pickup.map(&:order_id).uniq.count, :tues, '7:00 AM', 'send on day1')
    refute_reminders_emailed(:tues, '7:01 AM', 'dont send the second time')
  end

  test "dont send reminders for pay it forward items" do
    # change all the items to pay it forward
    day_1_items = Menu.current.order_items.day1_pickup
    refute day_1_items.empty?
    day_1_items.update_all(item_id: Item.pay_it_forward.id)

    refute_reminders_emailed(:tues, '7:00 AM', 'no emails should be sent since all items are now pay it forward')
  end

  test "reminders sent when orders placed on current menu during pickup_day2" do
    Setting.pickup_day1 = "Thursday"
    Setting.pickup_day2 = "Saturday"

    menu = Menu.current
    menu.update!(week_id: "19w47") # match the time travel for this test
    sat_9a = travel_to_day_time(:sat, "9:00 AM") do
      order = menu.orders.create!(user: users(:kyle))
      order.order_items.create!(item: items(:rye), day1_pickup: false)
    end
    refute_reminders_emailed(:sat, "9:00 AM", "no emails since orders are for this coming saturday")

    # go forward to end of week
    travel_to(DateTime.parse("2019-11-23 9:30 AM EST")) do
      assert_email_sent(1, "emails sent the next saturday") do
        SendDayOfReminderJob.perform_now
      end
    end

    # go forward to next next of week
    menu.messages.delete_all # delete messages so would resend
    travel_to(DateTime.parse("2019-11-30 9:30 AM EST")) do
      assert_email_sent(0, "emails not sent on the following saturday") do
        SendDayOfReminderJob.perform_now
      end
    end
  end

  private

  def order_item(user, item)
    users(user).orders.create!(menu: Menu.current).order_items.create!(item: item)
  end

  def refute_reminders_emailed(day, time, msg)
    assert_reminders_emailed(0, day, time, msg)
  end

  def assert_reminders_emailed(num_emails, day, time, msg)
    travel_to_day_time(day, time) do
      assert_email_sent(num_emails, msg) do
        SendDayOfReminderJob.perform_now
      end
    end
    if num_emails > 0
      assert_match /ReminderMailer#day_of_email/, Ahoy::Message.last.mailer, "sent by right mailer action"
    end
  end
end
