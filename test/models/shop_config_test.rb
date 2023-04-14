require 'test_helper'

class ShopConfigTest < ActiveSupport::TestCase
  test "same keys; has keys" do
    motzi, jinji = ["motzi", "jinji"].map() do |shop_id|
      ShopConfig.load_config_for_shop_id!(shop_id)
    end

    assert_equal motzi.keys, jinji.keys, "should have same keys"
    refute_equal motzi, jinji, "not same thing"
    refute motzi.empty?, "should have keys"
  end

  test "has important keys" do
    refute_nil ShopConfig.shop.id
    refute_nil ShopConfig.shop.name
    refute_nil ShopConfig.shop.short_name
    refute_nil ShopConfig.shop.marketing_domain
    refute_nil ShopConfig.shop.app_domain
    refute_nil ShopConfig.shop.email_reply_to
    refute_nil ShopConfig.shop.pay_it_forward
    refute_nil ShopConfig.shop.pay_what_you_can
  end

  test "non-existant shop" do
    assert_raise do
      ShopConfig.load_config_for_shop_id!("shoppy")
    end
  end
end
