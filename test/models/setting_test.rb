require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  test "same keys; has keys" do
    motzi, jinji = ["motzi", "jinji"].map() do |shop_id|
      lookup_shop(shop_id)
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
      lookup_shop("shoppy")
    end
  end

  private
  def lookup_shop(shop_id)
    Setting.send(:get_shop!, shop_id) # call private method get_shop!
  end
end