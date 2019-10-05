require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  test "items associate to orders" do
    w1 = orders(:kyle_week1)
    assert_equal w1.order_items.count, 1

    w2 = orders(:kyle_week2)
    assert_equal w2.order_items.count, 2

    item_names = w2.order_items.map(&:item).map(&:name)
    assert item_names.include?(items(:donuts).name), 'got donuts'
  end
end
