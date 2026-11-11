require "test_helper"

# The menu builder adds, edits and deletes pickup days through these JSON routes.
class Admin::PickupDaysControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "deleting a pickup day that has order items is refused and says how many" do
    pickup_day = pickup_days(:w1_d1_thurs)
    assert_equal 2, pickup_day.order_items.count

    assert_no_difference [ "PickupDay.count", "OrderItem.count" ] do
      delete "/admin/pickup_days/#{pickup_day.id}.json"
    end

    assert_response :unprocessable_entity
    assert_equal "Can't delete Thursday 01/03/19: 2 order items are for this pickup day. " \
                 "Move or remove those orders first.", response.parsed_body["error"]
  end

  test "deleting a pickup day with no order items works" do
    pickup_day = pickup_days(:w2_d2_sat)

    assert_difference "PickupDay.count", -1 do
      delete "/admin/pickup_days/#{pickup_day.id}.json"
    end

    assert_response :no_content
  end
end
