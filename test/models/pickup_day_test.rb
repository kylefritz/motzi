require 'test_helper'

class PickupDayTest < ActiveSupport::TestCase
  test "can find pickup day by date" do
    pickup_at = Time.zone.parse("2019-01-03 3:00 PM")
    pickup_day = PickupDay.for_pickup_at(pickup_at)
    assert pickup_day
  end

  test "pickup_day.day_str" do
    assert_equal "Thursday", pickup_days(:w1_d1_thurs).day_str
  end

  test "pickup_day.day_abbr" do
    assert_equal "Thu", pickup_days(:w1_d1_thurs).day_abbr
  end

  test "for_pickup_at & for_order_deadline_at" do
    deadline_at = Time.zone.parse("2021-01-03 9:00 PM") # 2am next day UTC
    pickup_at = deadline_at + 1.day
    pickup_day = PickupDay.create!(order_deadline_at: deadline_at, pickup_at: pickup_at, menu: menus(:week1))

    assert_equal pickup_day, PickupDay.for_pickup_at(pickup_at)
    assert_equal pickup_day, PickupDay.for_order_deadline_at(deadline_at)
    assert_nil PickupDay.for_order_deadline_at(pickup_at)
  end

  test "deadline text" do
    pickup_day = pickup_days(:w1_d1_thurs)
    assert_equal "for Thu (01/03) pickup, order by 5:00 PM Tue (01/01)", pickup_day.deadline_text
  end
end