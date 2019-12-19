require 'test_helper'

class LowCreditUsersTest < ActiveSupport::TestCase
  test "low credit users" do
    rows = SqlQuery.new(:low_credit_users, balance: 4).execute
    assert_equal 2, rows.size
    low_credit_users = [users(:ljf), users(:jess)]
    user_ids = Set[rows.map {|u| u["user_id"]}]
    assert_equal Set[low_credit_users.map(&:id)], user_ids

    balances = Set[rows.map {|u| u["credit_balance"]}]
    assert_equal Set[low_credit_users.map(&:credits)], balances
  end
end
