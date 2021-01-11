require 'test_helper'

class PickupDayTest < ActiveSupport::TestCase
  test "can find pickup day by date" do
    pickup_at = Time.zone.parse("2019-01-03 3:00 PM")
    pickup_day = PickupDay.for_pickup_at(pickup_at)
    assert pickup_day
  end

  test "pickup_day.pickup_day" do
    assert_equal "Thursday", pickup_days(:w1_d1_thurs).pickup_day
  end

  test "pickup_day.pickup_day_abbr" do
    assert_equal "Thu", pickup_days(:w1_d1_thurs).pickup_day_abbr
  end
end
