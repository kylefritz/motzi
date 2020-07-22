require 'test_helper'

class TimeWithZoneTest < ActiveSupport::TestCase
  test "week_id" do
    with_time do
      assert_equal Time.zone.now.week_id, '19w46'
    end
  end

  test 'from week_id - easy cases' do
    assert_week_id '2019-11-10', '19w46'
    assert_week_id '2019-12-22', '19w52'
  end

  test 'from week_id - crossing year boundary' do
    assert_week_id '2019-12-29', '20w01'
    assert_week_id '2020-01-05', '20w02'
  end

  test 'way back in time' do
    assert_week_id '2010-01-03', '10w02'
  end

  test 'reminder day' do
    with_time do
      monday = Time.zone.now
      assert monday.monday?

      Setting.pickup_day1 = "Tuesday"
      sunday = monday - 1.day
      assert sunday.reminder_day?, 'if day1 is tues, reminder is sunday'

      Setting.pickup_day1 = "Thursday"
      refute sunday.reminder_day?, 'if day1 is Thurs, reminder isnt sunday'
      tuesday = monday + 1.day
      assert tuesday.reminder_day?, 'if day1 is Thurs, reminder is tuesday'
    end
  end

  private
  def assert_week_id(date, week_id)
    datetime = DateTime.parse("#{date} 9:00 AM EST")
    assert datetime.sunday?
    assert_equal datetime, Time.zone.from_week_id(week_id)
  end

  def with_time(&block)
    travel_to(DateTime.parse("2019-11-11 9:00 AM EST")) do
      block.call
    end
  end
end
