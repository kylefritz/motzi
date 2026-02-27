require 'test_helper'

class ShopConfigTest < ActiveSupport::TestCase
  test "has config for motzi" do
    motzi = ShopConfig.load_config_for_shop_id!("motzi")

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

  test "no config for retired shops" do
    assert_raise do
      ShopConfig.load_config_for_shop_id!("jinji")
    end

    assert_raise do
      ShopConfig.load_config_for_shop_id!("dutch_courage")
    end
  end
end
