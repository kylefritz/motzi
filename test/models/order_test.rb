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

  test "item_list" do
    assert_equal "Tue: Donuts, Rye Five Ways", orders(:kyle_week2).item_list
    assert_equal 11, orders(:kyle_week2).retail_price

    orders(:ljf_week1).tap do |o|
      o.order_items.create!(item: items(:pumpkin), quantity: 5, day1_pickup: true)
      o.order_items.create!(item: items(:pumpkin), quantity: 1, day1_pickup: true)
      o.order_items.create!(item: items(:classic), quantity: 1, day1_pickup: true)
      assert_equal "Tue: Classic, 6x Pumpkin; Thu: Classic", o.item_list

      assert_equal 40, o.retail_price
    end

    Order.create!(menu: menus(:week1), user: users(:kyle)).tap do |o|
      o.order_items.create!(item: items(:pumpkin), quantity: 1, day1_pickup: true)
      o.order_items.create!(item: items(:pay_it_forward), quantity: 1, day1_pickup: true)
      assert_equal "Tue: Pumpkin; Pay it forward", o.item_list

      o.order_items.create!(item: items(:pay_it_forward), quantity: 2, day1_pickup: true)
      assert_equal "Tue: Pumpkin; 3x Pay it forward", o.item_list
    end
  end

  test "marketplace" do
    assert_equal 0, Order.marketplace.count
    Order.update_all(stripe_charge_amount: 6.0)
    assert_equal Order.count, Order.marketplace.count
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
    travel_to(known_day(day)) do
      block.call
    end
  end
end
