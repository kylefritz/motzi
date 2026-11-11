require "test_helper"

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

  test "for_pickup_at" do
    deadline_at = Time.zone.parse("2021-01-03 9:00 PM") # 2am next day UTC
    pickup_at = deadline_at + 1.day
    pickup_day = PickupDay.create!(order_deadline_at: deadline_at, pickup_at: pickup_at, menu: menus(:week1))

    assert_equal pickup_day, PickupDay.for_pickup_at(pickup_at).first
  end

  test "for_order_deadline_at" do
    deadline_at = Time.zone.parse("2021-01-03 9:00 PM") # 2am next day UTC
    pickup_at = deadline_at + 1.day
    pickup_day = PickupDay.create!(order_deadline_at: deadline_at, pickup_at: pickup_at, menu: menus(:week1))

    assert_equal pickup_day, PickupDay.for_order_deadline_at(deadline_at).first
    assert_nil PickupDay.for_order_deadline_at(pickup_at).first
  end

  # Order items are the record of what members ordered (and what their
  # credits paid for), so a pickup day that has any can't be deleted.
  test "a pickup day with order items can't be destroyed" do
    pickup_day = pickup_days(:w1_d1_thurs)
    assert_equal 2, pickup_day.order_items.count

    assert_no_difference [ "PickupDay.count", "OrderItem.count" ] do
      refute pickup_day.destroy
    end
    assert_equal [ "Can't delete Thursday 01/03/19: 2 order items are for this pickup day. " \
                   "Move or remove those orders first." ], pickup_day.errors.full_messages
  end

  test "a pickup day without order items can be destroyed, along with its menu item days" do
    pickup_day = pickup_days(:w2_d2_sat)
    assert_equal 0, pickup_day.order_items.count
    assert pickup_day.menu_item_pickup_days.any?

    assert_difference "PickupDay.count", -1 do
      assert pickup_day.destroy
    end
    assert_empty MenuItemPickupDay.where(pickup_day_id: pickup_day.id)
  end

  test "on_date matches the Eastern calendar date, not the UTC one" do
    evening = PickupDay.create!(menu: menus(:week1),
                                pickup_at: Time.zone.parse("2021-03-05 9:00 PM"), # 2am Mar 6 UTC
                                order_deadline_at: Time.zone.parse("2021-03-04 9:00 PM"))

    assert_equal [ evening ], PickupDay.on_date(Date.new(2021, 3, 5)).to_a
    assert_empty PickupDay.on_date(Date.new(2021, 3, 6))
  end

  test "deadline text" do
    pickup_day = pickup_days(:w1_d1_thurs)
    assert_equal "Thu, Jan 3 pickup after 3p — order by Tue, Jan 1 at 10p", pickup_day.deadline_text
  end
end
