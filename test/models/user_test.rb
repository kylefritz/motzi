require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "maya's password is wine" do
    maya = users(:maya)
    assert maya.authenticate('wine')
    refute maya.authenticate('not-wine')
    assert maya.is_admin
  end

  test "tuesday vs thursday pickup of the week" do
    assert users(:kyle).tuesday_pickup?
    refute users(:ljf).tuesday_pickup?
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
  end

  test "every_other_week" do
    assert_equal 1, User.every_other_week.count
    assert_equal users(:jess).id, User.every_other_week.first.id
  end

  test "tuesday_pickup" do
    assert_equal 2, User.tuesday_pickup.count, 'kf, adrian'
  end

  test "thursday_pickup" do
    assert_equal 2, User.thursday_pickup.count, 'ljf & jess'
  end
end
