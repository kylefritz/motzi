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

  test "with_feedback" do
    assert_difference 'Order.with_feedback.size', 1 do
      Order.create!(feedback: 'asd', menu: menus(:week2), user: users(:ljf))
    end
    assert_difference 'Order.with_feedback.size', 0, 'empty string' do
      Order.create!(feedback: '', menu: menus(:week2), user: users(:ljf))
    end
    assert_difference 'Order.with_feedback.size', 0, 'white space' do
      Order.create!(feedback: '    ', menu: menus(:week2), user: users(:ljf))
    end
  end

  test "with_comments" do
    assert_difference 'Order.with_comments.size', 1 do
      Order.create!(comments: 'asd', menu: menus(:week2), user: users(:ljf))
    end

    assert_difference 'Order.with_comments.size', 0, 'white space' do
      Order.create!(comments: '   ', menu: menus(:week2), user: users(:ljf))
    end

    assert_difference 'Order.with_comments.size', 0, 'empty string' do
      Order.create!(comments: '', menu: menus(:week2), user: users(:ljf))
    end

    assert_difference 'Order.with_comments.size', 0, 'Baker\'s choice isnt a comment' do
      Order.create!(comments: Order::BAKERS_CHOICE, menu: menus(:week2), user: users(:ljf))
    end
  end

  private

  # TODO: extract into test_helper
  def known_day(day, time="9:00 AM")
    days = {mon:   '11-11',
            tues:  '11-12',
            wed:   '11-13',
            thurs: '11-14',
            fri:   '11-15',
            sat:   '11-16',
            sun:   '11-17'}
    datetime_str = "2019-#{days[day]} #{time} EST"
    DateTime.parse(datetime_str)
  end

  def with_known_day(day, &block)
    Timecop.freeze(known_day(day)) do
      block.call
    end
  end
end
