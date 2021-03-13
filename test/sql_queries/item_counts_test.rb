require 'test_helper'

class ItemCountsTest < ActiveSupport::TestCase
  test "item_counts" do
    w1_classic, w1_pumpkin = menus(:week1).item_counts.values
    assert_equal [1, 1], w1_classic.values
    assert_equal [1], w1_pumpkin.values

    w2_rye, w2_donuts = menus(:week2).item_counts.values
    assert_equal [1], w2_rye.values
    assert_equal [1], w2_donuts.values

    menu = menus(:week3)
    day1, day2 = menu.pickup_days
    order = Order.create!(user: users(:kyle), menu: menu)
    order.order_items.create!(item: items(:classic), quantity: 100, pickup_day: day1)
    order.order_items.create!(item: items(:classic), quantity: 2, pickup_day: day2)
    assert_equal [100, 2], menu.item_counts.values.first.values
  end
end
