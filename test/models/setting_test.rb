require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "pickup instructions" do
    Setting.pickup_instructions = nil
    assert_nil Setting.pickup_instructions
    assert_equal "", Setting.pickup_instructions_html

    Setting.pickup_instructions = "#yo yo\n##yo yo"
    refute_nil Setting.pickup_instructions
    refute_nil Setting.pickup_instructions_html
  end

  test "homepage defaults to the menu and marketing is not live" do
    assert_equal "menu", Setting.homepage
    refute Setting.marketing_live?
  end

  test "homepage set to marketing makes the marketing site live" do
    Setting.homepage = "marketing"
    assert Setting.marketing_live?
    Setting.homepage = "menu"
    refute Setting.marketing_live?
  ensure
    Setting.homepage = "menu"
  end

  test "homepage only accepts menu or marketing" do
    assert_raises(ActiveRecord::RecordInvalid) { Setting.homepage = "wix" }
    record = Setting.new(var: "homepage", value: "bogus")
    refute record.valid?
    assert Setting.new(var: "homepage", value: "marketing").valid?
  end
end
