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
    assert_equal(-2, users(:ljf).credits)
    assert_equal 20, users(:kyle).credits

    # buy a multi-credit item
    menu = menus(:week1)
    order = users(:kyle).orders.create!(menu: menu)
    item = Item.create!(name: 'multi-credit item', credits: 6)
    pickup_day =  menu.pickup_days.first
    order.order_items.create!(item: item, pickup_day: pickup_day)
    assert_equal 20 - item.credits, users(:kyle).credits
  end

  test "receive_weekly_menu" do
    refute users(:maya).receive_weekly_menu?
    assert users(:kyle).receive_weekly_menu?
  end

  test "credit go down with items" do
    menu = menus(:week2)
    menu.make_current!
    pickup_day = menu.pickup_days.first
    kyle = users(:kyle)
    assert_difference 'kyle.credits', -1, 'added an item' do
      kyle.current_order.order_items.create!(item: items(:classic), pickup_day: pickup_day)
    end
  end

  test "credits dont change if we pay for order seperately" do
    menu = menus(:week2)
    menu.make_current!
    pickup_day = menu.pickup_days.first
    kyle = users(:kyle)
    kyle.current_order.update(stripe_charge_id: "fake-value")
    assert_difference 'kyle.credits', 0, 'added an item' do
      kyle.current_order.order_items.create!(item: items(:classic), pickup_day: pickup_day)
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

  test "receive_weekly_menu scope" do
    assert_equal 4, User.receive_weekly_menu.count, 'kf, adrian, ljf, jess'
    User.all.update_all(receive_weekly_menu: false)
    assert_equal 0, User.receive_weekly_menu.count
  end

  test "receive_havent_ordered_reminder scope gated by receive_weekly_menu" do
    count = User.receive_havent_ordered_reminder.count
    assert count > 0, 'some users should receive reminders'

    # turning off weekly menu should also exclude from havent_ordered reminder
    User.all.update_all(receive_weekly_menu: false)
    assert_equal 0, User.receive_havent_ordered_reminder.count
  end

  test "receive_havent_ordered_reminder scope respects its own flag" do
    User.where(receive_weekly_menu: true).update_all(receive_havent_ordered_reminder: false)
    assert_equal 0, User.receive_havent_ordered_reminder.count
  end

  test "receive_day_of_reminder scope" do
    count = User.receive_day_of_reminder.count
    assert count > 0
    User.all.update_all(receive_day_of_reminder: false)
    assert_equal 0, User.receive_day_of_reminder.count
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

  test "email_list" do
    assert_equal "laura@example.com", users(:ljf).email_list
    assert_equal "kyle.p.fritz@gmail.com, meg@example.com", users(:kyle).email_list
    assert_equal "jess@example.com", users(:jess).email_list
  end
end
