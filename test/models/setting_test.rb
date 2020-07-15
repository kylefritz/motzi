require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  test "same keys; has keys" do
    motzi, jinji = ["motzi", "jinji"].map() do |shop_id|
      Setting.find_shop_by_shop_id!(shop_id)
    end

    assert_equal motzi.keys, jinji.keys, "should have same keys"
    refute_equal motzi, jinji, "not same thing"
    refute motzi.empty?, "should have keys"
  end

  test "has important keys" do
    refute_nil Setting.shop.id
    refute_nil Setting.shop.name
    refute_nil Setting.shop.credit_prices
  end

  test "non-existant shop" do
    assert_raise do
      Setting.find_shop_by_shop_id!("shoppy")
    end
  end
end
