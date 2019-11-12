require 'test_helper'

class CreditEntryTest < ActiveSupport::TestCase
  test "users credit entries" do
    kyle = users(:kyle)
    assert_equal 26, kyle.credit_entries.first.quantity
  end
end
