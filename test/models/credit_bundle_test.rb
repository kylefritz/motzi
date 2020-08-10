require 'test_helper'

class CreditBundleTest < ActiveSupport::TestCase
  test "users credit items" do
    assert CreditBundle.create(credits: 20, price: 20).valid?
    refute CreditBundle.create(credits: 20, price: CreditBundle::MAX_PRICE + 1).valid?
    refute CreditBundle.create(credits: CreditBundle::MAX_CREDITS + 1, price: 20).valid?
  end
end
