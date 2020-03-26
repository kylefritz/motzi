require 'test_helper'

class SendDayOfReminderJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  def setup
    menus(:week2).make_current!
  end

  test "dont send on wrong day of week" do
    refute_reminders_emailed(:mon, '10:00 AM', 'dont send on mon')
    refute_reminders_emailed(:wed, '10:00 AM', 'dont send on wed')
  end

  test "Sends at right time" do
    refute_reminders_emailed(:tues, '5:00 AM', 'dont send too early')
    refute_reminders_emailed(:thurs, '5:00 AM', 'dont send too early')
    assert_reminders_emailed(Menu.current.orders.day1_pickup.count, :tues, '7:00 AM', 'send on day1/tues')
    assert_reminders_emailed(Menu.current.orders.day2_pickup.count, :thurs, '7:00 AM', 'send on day2/thurs; not to jess')
  end

  test "Sends according to pickup day settings" do
    Setting.pickup_day1 = "Thursday"
    Setting.pickup_day2 = "Saturday"

    assert_reminders_emailed(Menu.current.orders.day1_pickup.count, :thurs, '7:00 AM', 'send on day1/thurs')
    assert_reminders_emailed(Menu.current.orders.day2_pickup.count, :sat, '7:00 AM', 'send on day2/sat; not to jess')
  end

  test "includes all users who've ordered" do
    order_item(:jess, items(:classic))
    assert_reminders_emailed(Menu.current.orders.day2_pickup.count, :thurs, '7:00 AM', 'sends to jess too')
  end

  test "but not users who've skipped" do
    order_item(:jess, Item.skip)
    assert_reminders_emailed(Menu.current.orders.day2_pickup.count - 1, :thurs, '7:00 AM', 'sends to jess too')
  end

  test "weekly orders who skipped shouldn't get reminders" do
    Menu.current.orders.day2_pickup.delete_all
    assert Menu.current.orders.day2_pickup.empty?, 'cleared the orders'
    order_item(:ljf, Item.skip)
    assert_reminders_emailed(0, :thurs, '7:00 AM', 'shouldnt send to laura since skipped')
  end

  test "Doesnt send to users multiple times on same menu" do
    assert_reminders_emailed(Menu.current.orders.day1_pickup.count, :tues, '7:00 AM', 'send on day1')
    refute_reminders_emailed(:tues, '7:01 AM', 'dont send the second time')
  end

  private

  def order_item(user, item)
    users(user).orders.create!(menu: Menu.current).order_items.create!(item: item)
  end

  def refute_reminders_emailed(day, time, msg)
    assert_reminders_emailed(0, day, time, msg)
  end

  def assert_reminders_emailed(num_emails, day, time, msg)
    days = {mon:   '11-11',
            tues:  '11-12',
            wed:   '11-13',
            thurs: '11-14',
            fri:   '11-15',
            sat:   '11-16',
            sun:   '11-17'}
    assert days.include?(day), 'pick a known day'
    datetime_str = "2019-#{days[day]} #{time} EST"
    date_time = DateTime.parse(datetime_str)
    Timecop.freeze(date_time) do
      assert_difference('Ahoy::Message.count', num_emails, 'emails audited in ahoy') do
        assert_difference('ReminderMailer.deliveries.count', num_emails, msg) do
          perform_enqueued_jobs do
            SendDayOfReminderJob.perform_now
          end
        end
      end
    end

    if num_emails > 0
      assert_equal 'ReminderMailer#day_of_email', Ahoy::Message.last.mailer, 'sent by right mailer action'
    end
  end
end
