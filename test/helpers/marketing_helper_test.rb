require "test_helper"

class MarketingHelperTest < ActionView::TestCase
  include MarketingHelper

  test "holiday_menu_link returns nil when no current holiday" do
    Setting.holiday_menu_id = nil
    assert_nil holiday_menu_link
  end

  test "holiday_menu_link returns a link while ordering is open" do
    holiday = menus(:passover_2026)
    Setting.holiday_menu_id = holiday.id

    travel_to Time.zone.parse("2026-09-01 10:00") do
      link = holiday_menu_link
      assert_not_nil link
      assert_match holiday.name, link
      assert_match menu_path(holiday), link
    end
  ensure
    Setting.holiday_menu_id = nil
  end

  test "holiday_menu_link returns nil once all ordering deadlines have passed" do
    holiday = menus(:passover_2026)
    Setting.holiday_menu_id = holiday.id

    travel_to Time.zone.parse("2026-10-01 10:00") do
      assert_nil holiday_menu_link
    end
  ensure
    Setting.holiday_menu_id = nil
  end

  test "holiday_menu_link returns nil when the holiday menu has no pickup days" do
    holiday = Menu.create!(name: "Rosh Hashanah Pre-orders", week_id: "26w36", menu_type: "holiday")
    Setting.holiday_menu_id = holiday.id

    assert_nil holiday_menu_link
  ensure
    Setting.holiday_menu_id = nil
    holiday&.destroy
  end

  test "subscription_option derives copy from the bundle" do
    weekly = credit_bundles(:mo6_weekly)
    assert_equal "$169 for 26 credits ($6.50 per loaf). This is one loaf of bread every week for six months.",
                 strip_tags(subscription_option(weekly))

    biweekly = credit_bundles(:"mo6_bi-weekly")
    assert_equal "$91 for 13 credits ($7.00 per loaf). This is one loaf of bread every other week for six months.",
                 strip_tags(subscription_option(biweekly))

    three_month = credit_bundles(:mo3_weekly)
    assert_equal "$91 for 13 credits ($7.00 per loaf). This is one loaf of bread every week for three months.",
                 strip_tags(subscription_option(three_month))
  end
end
