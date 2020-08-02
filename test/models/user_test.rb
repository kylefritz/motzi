require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "maya's password is wine" do
    maya = users(:maya)
    assert maya.authenticate('wine')
    refute maya.authenticate('not-wine')
    assert maya.is_admin
    assert_equal maya.id, User.maya.id
  end

  test "credits remaining" do
    assert_equal 0, users(:ljf).credits
    assert_equal 23, users(:kyle).credits


    order = users(:kyle).orders.create!(menu: menus(:week1))
    item = Item.create!(name: 'multi-credit item', credits: 6)
    order.order_items.create!(item: item,)
    assert_equal 23 - item.credits, users(:kyle).credits
  end

  test "subscriber" do
    refute users(:maya).subscriber?
    assert users(:kyle).subscriber?
  end

  test "credit go down with items" do
    menus(:week2).make_current!
    kyle = users(:kyle)
    assert_difference 'kyle.credits', -1, 'added an item' do
      kyle.current_order.order_items.create!(item: items(:classic))
    end
  end

  test "credits dont change if we pay for order seperately" do
    menus(:week2).make_current!
    kyle = users(:kyle)
    kyle.current_order.update(stripe_charge_id: "fake-value")
    assert_difference 'kyle.credits', 0, 'added an item' do
      kyle.current_order.order_items.create!(item: items(:classic))
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

  test "subscribers" do
    assert_equal 4, User.subscribers.count, 'kf, adrian, ljf, jess'
    User.all.update_all(subscriber: false)
    assert_equal 0, User.subscribers.count
  end

  test "order for menu" do
    menu = menus(:week2)

    refute_nil users(:kyle).order_for_menu(menu), "customer has order"

    assert_nil users(:maya).order_for_menu(menu), "owner doesn't have order"

    recent_order = menu.orders.create!(user: users(:kyle))
    assert_equal 2, users(:kyle).orders.where(menu: menu).count
    refute_nil users(:kyle).order_for_menu(menu), "if two, finds one"
    assert_equal recent_order.id, users(:kyle).order_for_menu(menu).id
  end

  test "email normalized" do
    email = "someone@bread.com"
    user = User.create!(email: "   #{email.upcase}   ", password: "sadfsfsdf")
    assert_equal email, user.email
  end
end
