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

  test "skip" do
    kyle = users(:kyle)
    order = kyle.orders.create!(menu: menus(:week2))
    assert order.skip?, 'no items means skip'

    order.order_items.create(item: Item.skip)
    assert order.skip?, 'skip item means skip'

    order.order_items.create(item: items(:classic))
    refute order.skip?, 'any item means not skip'
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
      Order.create!(comments: Item.bakers_choice.name, menu: menus(:week2), user: users(:ljf))
    end
  end

  test "pickup_day" do
    menu = menus(:week3) # no orders
    menu.make_current!

    assert_difference 'Menu.current.orders.tuesday_pickup.size', 0, 'no tuesday order' do
      assert_difference 'Menu.current.orders.thursday_pickup.size', 1, 'add thursday order' do
        thurs_user = users(:ljf)
        assert thurs_user.thursday_pickup?, 'picks up thursday'
        Order.create!(menu: menu, user: thurs_user)
      end
    end

    assert_difference 'Menu.current.orders.thursday_pickup.size', 0, 'no thursday order' do
      assert_difference 'Menu.current.orders.tuesday_pickup.size', 1, 'add tuesday order' do
        tues_user = users(:kyle)
        assert tues_user.tuesday_pickup?, 'picks up tuesday'
        Order.create!(menu: menu, user: tues_user)
      end
    end

    orders = menus(:week1).orders
    assert_equal orders.size, orders.tuesday_pickup.size + orders.thursday_pickup.size, 'tues+thurs=total'

    orders = menus(:week2).orders
    assert_equal orders.size, orders.tuesday_pickup.size + orders.thursday_pickup.size, 'tues+thurs=total'
  end

end
