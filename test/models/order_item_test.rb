require 'test_helper'

class OrderItemTest < ActiveSupport::TestCase
  test "name" do
    assert_equal "OrderItem #984104125 in Order #727584411", order_items(:k_w1_pumpkin_day1).name
  end

  test "day" do
    assert_equal "Tuesday", order_items(:k_w1_pumpkin_day1).day
    assert_equal "Thursday", order_items(:ljf_w1_classic_day2).day

    assert_nil make_order_item(item: Item.pay_it_forward).day
  end

  test "scopes" do
    assert_difference('OrderItem.day1_pickup.count', 1, 'day1_pickup') do
      make_order_item(pickup: :day1)
    end
    assert_difference('OrderItem.day2_pickup.count', 1, 'day2_pickup') do
      make_order_item(pickup: :day2)
    end
    assert_difference('OrderItem.requires_pickup.count', 2, 'requires_pickup') do
      make_order_item(pickup: :day1)
      make_order_item(pickup: :day2)
    end
    assert_difference('OrderItem.requires_pickup.count', 0, 'requires_pickup') do
      make_order_item(item: Item.pay_it_forward)
    end
  end

  def make_order_item(item: items(:classic), pickup: :day1)

    orders(:kyle_week1).order_items.create!(item: item,
                                            day1_pickup: (pickup == :day1))
  end
end
