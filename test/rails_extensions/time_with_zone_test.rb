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
    assert_week_id '2010-01-03', '10w01'
  end

  test 'late 2020 from_week_id' do
    assert_roundtrip '2020-12-27 9:00 AM EST', '20w53'
  end

  test 'early 2020 from_week_id' do
    assert_roundtrip '2019-12-29 9:00 AM EST', '20w01'
  end

  test '2019 from_week_id' do
    assert_roundtrip '2019-12-22 9:00 AM EST', '19w52'
  end

  test 'current week_id at end of 2020' do
    travel_to(DateTime.parse('2020-12-27 10:00 AM EST')) do
      assert_equal Time.zone.now.week_id, '20w53'
    end
  end

  test '2010-01-03' do
    assert_cweek'2010-01-03', 1
  end

  test '2020-12-26' do
    assert_cweek'2020-12-26', 52
  end

  test '2020-12-27' do
    assert_cweek'2020-12-27', 53
  end

  test '2020-12-28' do
    assert_cweek'2020-12-28', 53
  end

  test '2020-12-31' do
    assert_cweek'2020-12-31', 53
  end

  test '2021-01-01' do
    assert_cweek'2021-01-01', 53
  end

  test '2021-01-02' do
    assert_cweek'2021-01-02', 53
  end

  test '2021-01-03' do
    assert_cweek'2021-01-03', 1
  end

  test '2021-01-31' do
    assert_cweek'2021-01-31', 5
  end

  test '2021-02-01' do
    assert_cweek'2021-02-01', 5
  end

  test '2021 from_week_id new' do
    assert_equal Time.zone.from_week_id('21w05'), Time.zone.parse('2021-01-31 9:00 AM EST')
  end

  test '2021 week_id_new' do
    assert_equal Time.zone.parse('2021-01-31 9:00 AM EST').week_id, '21w05'
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

  def assert_cweek(date_str, cweek)
    assert_equal Time.zone.parse("#{date_str} 9:00 AM EST").cweek, cweek
  end

  def assert_roundtrip(datetime_str, week_id)
    assert_equal Time.zone.from_week_id(week_id), Time.zone.parse(datetime_str)
    assert_equal Time.zone.parse(datetime_str).week_id, week_id
  end
end
