require 'test_helper'

class UserCreditsTest < ActiveSupport::TestCase
  test "user_credits" do
    users = User.all
    rows = SqlQuery.new(:user_credits, user_ids: users.map(&:id)).execute
    balances = Hash[rows.map {|r| [r["user_id"], r["credit_balance"]]} ]

    assert_equal users.size, rows.size, "same number of users as rows"
    assert_equal users.size, balances.size, "same number of users as balances"

    users.each do |user|
      assert_equal user.credits, balances[user.id], "#{user.name}"
    end    
  end
end
