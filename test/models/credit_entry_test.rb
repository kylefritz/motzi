require 'test_helper'

class CreditEntryTest < ActiveSupport::TestCase
  test "users credit entries" do
    kyle = users(:kyle)
    assert_equal kyle.credit_entries.first.quantity, 26
  end
end
