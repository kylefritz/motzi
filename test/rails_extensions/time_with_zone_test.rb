require 'test_helper'

class TimeWithZoneTest < ActiveSupport::TestCase
  test "week_id" do
    with_time do
      assert_equal Time.zone.now.week_id, '19w46'
    end
  end

  test 'from week_id' do
    assert_equal DateTime.parse("2019-11-10 9:00 AM EST"), Time.zone.from_week_id('19w46')
  end

  private
  def with_time(&block)
    Timecop.freeze(DateTime.parse("2019-11-11 9:00 AM EST")) do
      block.call
    end
  end
end
