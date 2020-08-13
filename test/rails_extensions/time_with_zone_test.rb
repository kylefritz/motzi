require 'test_helper'

class TimeWithZoneTest < ActiveSupport::TestCase
  test "week_id" do
    with_time do
      assert_equal Time.zone.now.week_id, '19w46'
    end
  end

  test "roundtrip" do
    time = Time.zone.from_week_id("19w46")
    assert_equal time, Time.zone.parse("2019-11-10 9:00 AM EST")
    assert_equal time.week_id, "19w46"
    assert_equal time.prev_week_id, "19w45"

    assert_equal Time.zone.parse("2019-11-10 8:59 AM EST").week_id, "19w45"
    assert_equal Time.zone.parse("2019-11-17 9:01 AM EST").week_id, "19w47"

    assert_equal Time.zone.parse("2019-12-22 9:00 AM EST").week_id, "19w52"
    assert_equal Time.zone.parse("2019-12-29 9:00 AM EST").week_id, "20w01"
  end

  test "travel_to_week_id" do
    travel_to_week_id("19w46") do
      assert_equal Time.zone.now.week_id, "19w46"
    end
  end

  test "from_week_id" do
    week_ids = date_times = [
      "19w51",
      "19w52",
      "20w01",
      "20w02",
    ]
    assert_equal week_ids.map{|week_id| Time.zone.from_week_id(week_id).week_id}, week_ids
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
    travel_to(DateTime.parse("2019-11-11 9:00 AM EST")) do
      block.call
    end
  end
end
