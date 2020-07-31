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
    refute_nil Setting.shop.short_name
    refute_nil Setting.shop.marketing_domain
    refute_nil Setting.shop.app_domain
    refute_nil Setting.shop.email_reply_to
    refute_nil Setting.shop.pay_it_forward
    refute_nil Setting.shop.pay_what_you_can
  end

  test "non-existant shop" do
    assert_raise do
      Setting.find_shop_by_shop_id!("shoppy")
    end
  end

  test "pickup instructions" do
    Setting.pickup_instructions = nil
    assert_nil Setting.pickup_instructions
    assert_equal "", Setting.pickup_instructions_html

    Setting.pickup_instructions = "#yo yo\n##yo yo"
    refute_nil Setting.pickup_instructions
    refute_nil Setting.pickup_instructions_html
  end
end
