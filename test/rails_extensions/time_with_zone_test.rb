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

  private
  def assert_week_id(date, week_id)
    datetime = DateTime.parse("#{date} 9:00 AM EST")
    assert datetime.sunday?
    assert_equal datetime, Time.zone.from_week_id(week_id)
  end

  def with_time(&block)
    Timecop.freeze(DateTime.parse("2019-11-11 9:00 AM EST")) do
      block.call
    end
  end
end
