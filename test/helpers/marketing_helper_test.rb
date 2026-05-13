require 'test_helper'

class MarketingHelperTest < ActionView::TestCase
  include MarketingHelper

  test "holiday_menu_link returns nil when no current holiday" do
    Setting.holiday_menu_id = nil
    assert_nil holiday_menu_link
  end

  test "holiday_menu_link returns a link to the menu when one is current" do
    holiday = Menu.create!(name: "Rosh Hashanah Pre-orders", week_id: "26w36", menu_type: "holiday")
    Setting.holiday_menu_id = holiday.id

    link = holiday_menu_link
    assert_not_nil link
    assert_match holiday.name, link
    assert_match menu_path(holiday), link
  ensure
    Setting.holiday_menu_id = nil
    holiday&.destroy
  end
end
