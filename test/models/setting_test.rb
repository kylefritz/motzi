require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  test "pickup instructions" do
    Setting.pickup_instructions = nil
    assert_nil Setting.pickup_instructions
    assert_equal "", Setting.pickup_instructions_html

    Setting.pickup_instructions = "#yo yo\n##yo yo"
    refute_nil Setting.pickup_instructions
    refute_nil Setting.pickup_instructions_html
  end
end
