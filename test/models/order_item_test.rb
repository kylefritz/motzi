require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  test "name" do
    assert_equal "OrderItem #984104125 in Order #727584411", order_items(:k_w1_pumpkin_day1).name
  end

  test "day" do
    assert_equal "Thursday", order_items(:k_w1_pumpkin_day1).day
    assert_equal "Saturday", order_items(:ljf_w1_classic_day2).day
  end

  test "snapshots item pricing on create" do
    order_item = make_order_item(item: items(:donuts))

    assert_equal items(:donuts).credits, order_item.credits
    assert_equal items(:donuts).price, order_item.price
  end

  test "snapshot survives later item repricing" do
    order_item = make_order_item(item: items(:donuts))

    items(:donuts).update!(price: 99, credits: 42)

    assert_equal 1, order_item.reload.credits
    assert_equal 6, order_item.reload.price
  end

  def make_order_item(item: items(:classic), pickup: pickup_days(:w1_d1_thurs))
    orders(:kyle_week1).order_items.create!(item: item, pickup_day: pickup)
  end
end
