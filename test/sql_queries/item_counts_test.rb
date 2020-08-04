require 'test_helper'

class ItemCountsTest < ActiveSupport::TestCase
  test "user_credits" do
    w1d1, w1d2 = menus(:week1).item_counts
    assert_equal [1, 1], w1d1.values
    assert_equal [1], w1d2.values

    w2d1, w2d2 = menus(:week2).item_counts
    assert_equal [1, 1], w2d1.values
    assert_equal [], w2d2.values

    order = Order.create!(user: users(:kyle), menu: menus(:week3))
    order.order_items.create!(item: items(:classic), quantity: 100, day1_pickup: false)
    order.order_items.create!(item: items(:classic), quantity: 2, day1_pickup: false)
    w3d1, w3d2 = menus(:week3).item_counts
    assert_equal [], w3d1.values
    assert_equal [items(:classic).id, 102], w3d2.entries.first
  end
end
