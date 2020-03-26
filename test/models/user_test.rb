require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "maya's password is wine" do
    maya = users(:maya)
    assert maya.authenticate('wine')
    refute maya.authenticate('not-wine')
    assert maya.is_admin
    assert_equal maya.id, User.maya.id
  end

  test "day1 vs day2 pickup of the week" do
    assert users(:kyle).day1_pickup?
    refute users(:ljf).day1_pickup?
  end

  test "credits remaining" do
    assert_equal 0, users(:ljf).credits
    assert_equal 23, users(:kyle).credits
  end

  test "credit go down with items" do
    menus(:week2).make_current!
    kyle = users(:kyle)
    assert_difference 'kyle.credits', -1, 'added an item' do
      kyle.current_order.order_items.create!(item: items(:classic))
    end
  end

  test "skips dont cost credits" do
    menus(:week2).make_current!
    kyle = users(:kyle)
    assert_difference 'kyle.credits', 0, 'added a skip item' do
      kyle.current_order.order_items.create!(item: Item.skip)
    end
  end

  test "current order" do
    menus(:week2).make_current!
    assert_nil users(:ljf).current_order, 'shouldnt have an order'
    assert_equal orders(:kyle_week2), users(:kyle).current_order, 'has already ordered'
  end

  test "blank name" do
    email = "someone@bread.com"
    user = User.create!(email: email, password: "sadfsfsdf")
    assert_equal email, user.name, 'email is fallback for name'
  end

  test "owners" do
    assert_equal 2, User.owners.count
  end

  test "for_bakers_choice" do
    menus(:week2).make_current!
    assert_equal 2, User.for_bakers_choice.count
  end

  test "must_order_weekly" do
    assert_equal 3, User.must_order_weekly.count
    assert User.must_order_weekly.first.must_order_weekly?
  end

  test "every_other_week" do
    assert_equal 1, User.every_other_week.count
    assert_equal users(:jess).id, User.every_other_week.first.id
    assert User.every_other_week.first.every_other_week?
  end

  test "day1_pickup" do
    assert_equal 2, User.day1_pickup.count, 'kf, adrian'
    assert User.day1_pickup.first.day1_pickup?
  end

  test "day2" do
    assert_equal 2, User.day2_pickup.count, 'ljf & jess'
    assert User.day2_pickup.first.day2_pickup?
  end

  test "only sends to weekly" do
    User.all.update_all(send_weekly_email: false)
    assert_equal 0, User.day1_pickup.count
    assert_equal 0, User.day2_pickup.count
  end

  test "customers" do
    assert_equal 4, User.customers.count, 'kf, adrian, ljf, jess'
    User.all.update_all(send_weekly_email: false)
    assert_equal 0, User.customers.count
  end
end
