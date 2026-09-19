require "test_helper"

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

  test "app_domain prefers CANONICAL_HOST" do
    env = { "CANONICAL_HOST" => "motzibread.com", "HEROKU_APP_NAME" => "motzibread-pr-9" }
    assert_equal "motzibread.com", ShopConfig.app_domain(env)
  end

  test "app_domain falls back to the heroku app name" do
    assert_equal "motzibread-pr-9.herokuapp.com", ShopConfig.app_domain("HEROKU_APP_NAME" => "motzibread-pr-9")
    assert_equal "motzibread-pr-9.herokuapp.com",
                 ShopConfig.app_domain("CANONICAL_HOST" => "", "HEROKU_APP_NAME" => "motzibread-pr-9")
  end

  test "app_domain falls back to shop.yml" do
    assert_equal ShopConfig.shop.app_domain, ShopConfig.app_domain({})
    assert_equal ShopConfig.shop.app_domain, ShopConfig.app_domain("HEROKU_APP_NAME" => "")
  end
end
