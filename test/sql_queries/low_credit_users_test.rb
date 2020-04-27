require 'test_helper'

class LowCreditUsersTest < ActiveSupport::TestCase
  test "low credit users" do
    rows = exec_low_credit_users
    assert_equal 2, rows.size
    low_credit_users = [users(:ljf), users(:jess)]
    user_ids = Set[rows.map {|u| u["user_id"]}]
    assert_equal Set[low_credit_users.map(&:id)], user_ids

    balances = Set[rows.map {|u| u["credit_balance"]}]
    assert_equal Set[low_credit_users.map(&:credits)], balances
  end

  test "doesnt charge for skip" do
    kyle = users(:kyle)
    menu = menus(:week2)

    # synthesize enough orders that kyle will be in the "low-credit" list
    _, items = menu.menu_items.partition(&:is_add_on?)
    new_kyle_orders = kyle.credits.times.map do
      kyle.orders.create!(menu: menu).tap do |order|
        order.order_items.create!(item: items.sample.item)
      end
    end
    assert_equal 0, kyle.credits, 'now kyle has no credits'
    assert_equal 3, exec_low_credit_users.size, 'kyle included in low credit users'
  end

  test "dont show users who dont get emails" do
    User.all.update_all(send_weekly_email: false)
    assert_equal 0, exec_low_credit_users.size
  end

  private
  def exec_low_credit_users
    SqlQuery.new(:low_credit_users, balance: 4).execute
  end
end
