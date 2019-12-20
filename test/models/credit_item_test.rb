require 'test_helper'

class CreditItemTest < ActiveSupport::TestCase
  test "users credit items" do
    kyle = users(:kyle)
    assert_equal 26, kyle.credit_items.first.quantity
  end
end
