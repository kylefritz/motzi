require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  test "items associate to orders" do
    w1 = orders(:kyle_week1)
    assert_equal 1, w1.order_items.count

    w2 = orders(:kyle_week2)
    assert_equal 2, w2.order_items.count

    item_names = w2.order_items.map(&:item).map(&:name)
    assert_includes item_names, items(:donuts).name, 'got donuts'
  end

  test "associate orders to users" do
    kyle = users(:kyle)
    assert_equal 2, kyle.orders.count
  end
end
