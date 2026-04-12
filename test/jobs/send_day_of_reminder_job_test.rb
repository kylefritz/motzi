require 'test_helper'

class SendDayOfReminderJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  def setup
    @menu = menus(:week1)
    @menu.make_current!

    # match the time travel for this test
    @tues, @thurs = @menu.pickup_days.all
    @tues.update!(pickup_at: "2019-11-12 3:00 PM")
    @thurs.update!(pickup_at: "2019-11-14 3:00 PM")
  end

  test "Sends at right time" do
    refute_reminders_emailed(:tues, '5:00 AM', 'dont send too early')
    refute_reminders_emailed(:thurs, '5:00 AM', 'dont send too early')
    assert_commented do
      assert_reminders_emailed(2, :tues, '7:00 AM', 'send on day1/tues')
    end
    assert_reminders_emailed(1, :thurs, '7:00 AM', 'send on day2/thurs; not to jess')
    refute_reminders_emailed(:tues, '1:00 PM', 'dont send too early')
    refute_reminders_emailed(:thurs, '1:00 PM', 'dont send too late')
  end

  test "dont send on wrong day of week" do
    refute_reminders_emailed(:mon, '10:00 AM', 'dont send on mon')
    refute_reminders_emailed(:wed, '10:00 AM', 'dont send on wed')
  end

  test "includes all users who've ordered" do
    order_item(:jess, items(:classic))
    assert_reminders_emailed(2, :thurs, '7:00 AM', 'sends to jess too')
  end

  test "orders with no items shouldn't get reminders" do
    @thurs.order_items.destroy_all
    assert @thurs.order_items.empty?, 'cleared the orders'
    assert_reminders_emailed(0, :thurs, '7:00 AM', 'shouldnt send since no items')
  end

  test "Doesnt send to users multiple times on same menu" do
      assert_reminders_emailed(2, :tues, '7:00 AM', 'send on day1')
    refute_reminders_emailed(:tues, '7:01 AM', 'dont send the second time')
  end

  test "does not send duplicate emails when user has multiple orders" do
    # Create a second order for kyle on the same menu
    second_order = users(:kyle).orders.create!(menu: @menu)
    second_order.order_items.create!(item: items(:classic), pickup_day: @tues)

    assert_reminders_emailed(2, :tues, '7:00 AM', 'kyle gets one email despite two orders')
  end

  test "includes items from all orders when user has multiple orders" do
    # Kyle's first order has pumpkin on tues. Add a second order with classic.
    second_order = users(:kyle).orders.create!(menu: @menu)
    second_order.order_items.create!(item: items(:classic), pickup_day: @tues)

    ActionMailer::Base.deliveries.clear

    travel_to_day_time(:tues, '7:00 AM') do
      SendDayOfReminderJob.perform_now
    end

    # The email should reference both items (from both orders)
    email = ActionMailer::Base.deliveries.find { |e| e.to.include?(users(:kyle).email) }
    assert email, "email should have been delivered to kyle"
    body = email.text_part&.body.to_s + email.html_part&.body.to_s
    assert_match(/pumpkin/i, body, "email should include pumpkin from first order")
    assert_match(/classic/i, body, "email should include classic from second order")
  end

  test "respects receive_day_of_reminder preference" do
    users(:kyle).update!(receive_day_of_reminder: false)
    # kyle has an order for tues, but opted out of day-of reminders
    assert_reminders_emailed(1, :tues, '7:00 AM', 'only adrian gets reminded, not kyle')
  end

  test "dont send reminders for pay it forward items" do
    # change all the items to pay it forward
    refute @tues.order_items.empty?
    @tues.order_items.update_all(item_id: Item.pay_it_forward.id)

    refute_reminders_emailed(:tues, '7:00 AM', 'no emails should be sent since all items are now pay it forward')
  end

  private

  def order_item(user, item)
    users(user).orders.create!(menu: Menu.current).order_items.create!(item: item, pickup_day: Menu.current.pickup_days.last)
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
      assert_match /ReminderMailer#day_of_email/, Ahoy::Message.last.mailer, 'sent by right mailer action'
    end
  end
end
