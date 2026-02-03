require 'test_helper'

class SendDayOfReminderJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  def setup
    @menu = menus(:week1)
    @menu.make_current!

    # match the time travel for this test
    @tues, @thurs = @menu.pickup_days.all
    @tues.update!(pickup_at: '2019-11-12 3:00 PM')
    @thurs.update!(pickup_at: '2019-11-14 3:00 PM')
  end

  test 'Sends at right time' do
    refute_reminders_emailed(:tues, '5:00 AM', 'dont send too early')
    refute_reminders_emailed(:thurs, '5:00 AM', 'dont send too early')
    assert_commented do
      assert_reminders_emailed(2, :tues, '7:00 AM', 'send on day1/tues')
    end
    assert_reminders_emailed(1, :thurs, '7:00 AM', 'send on day2/thurs; not to jess')
    refute_reminders_emailed(:tues, '1:00 PM', 'dont send too early')
    refute_reminders_emailed(:thurs, '1:00 PM', 'dont send too late')
  end

  test 'dont send on wrong day of week' do
    refute_reminders_emailed(:mon, '10:00 AM', 'dont send on mon')
    refute_reminders_emailed(:wed, '10:00 AM', 'dont send on wed')
  end

  test "includes all users who've ordered" do
    order_item(:jess, items(:classic))
    assert_reminders_emailed(2, :thurs, '7:00 AM', 'sends to jess too')
  end

  test "weekly orders who skipped shouldn't get reminders" do
    @thurs.order_items.destroy_all
    assert @thurs.order_items.empty?, 'cleared the orders'
    assert_reminders_emailed(0, :thurs, '7:00 AM', 'shouldnt send to laura since skipped')
  end

  test 'Doesnt send to users multiple times on same menu' do
    assert_reminders_emailed(2, :tues, '7:00 AM', 'send on day1')
    refute_reminders_emailed(:tues, '7:01 AM', 'dont send the second time')
  end

  test 'dont send reminders for pay it forward items' do
    # change all the items to pay it forward
    refute @tues.order_items.empty?
    @tues.order_items.update_all(item_id: Item.pay_it_forward.id)

    refute_reminders_emailed(:tues, '7:00 AM', 'no emails should be sent since all items are now pay it forward')
  end

  test 'combines overlapping menus into one day-of reminder' do
    valentine_week = menus(:valentine_week)
    valentine_week.make_current!

    travel_to(Time.zone.parse('2026-02-14 07:00 AM')) do
      assert_email_sent(2, 'handle special + weekly menus in a single email') do
        SendDayOfReminderJob.perform_now
      end

      jess_messages = Ahoy::Message.where(user: users(:jess), mailer: 'ReminderMailer#day_of_email')
      assert_equal 1, jess_messages.count, 'still only one email per user even with two menus'

      body = ActionMailer::Base.deliveries.last.body.encoded
      assert_match menus(:valentine_special).name, body
      assert_match menus(:valentine_week).name, body

      assert_equal 1, ActiveAdmin::Comment.where(resource: menus(:valentine_week)).count, 'regular menu gets a comment'
      assert_equal 1, ActiveAdmin::Comment.where(resource: menus(:valentine_special)).count,
                   'special menu gets a comment'
    end
  end

  private

  def order_item(user, item)
    users(user).orders.create!(menu: Menu.current).order_items.create!(item: item,
                                                                       pickup_day: Menu.current.pickup_days.last)
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
    return unless num_emails > 0

    assert_match(/ReminderMailer#day_of_email/, Ahoy::Message.last.mailer, 'sent by right mailer action')
  end
end
