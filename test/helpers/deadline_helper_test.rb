require "test_helper"

class DeadlineHelperTest < ActiveSupport::TestCase
  include DeadlineHelper

  def setup
    @menu = menus(:week1)
    @menu.update!(week_id: Time.zone.now.week_id)
  end

  test "defaults" do
    assert_day1_formatted "9pm Sunday"
    assert_day2_formatted "9pm Tuesday"

    assert_ordering_deadline_text "9pm Sunday for Tuesday pickup or 9pm Tuesday for Thursday pickup"
  end

  test "motzi" do
    Setting.pickup_day1 = "Thursday"
    Setting.pickup_day2 = "Saturday"
    Setting.leadtime_hours = 27

    assert_day1_formatted "9pm Tuesday"
    assert_day2_formatted "9pm Thursday"

    assert_ordering_deadline_text "9pm Tuesday for Thursday pickup or 9pm Thursday for Saturday pickup"
  end

  test "jinji" do
    Setting.pickup_day1 = "Thursday"
    Setting.pickup_day2 = "Saturday"
    Setting.leadtime_hours = 24

    assert_day1_formatted "12am Wednesday"
    assert_day2_formatted "12am Friday"

    assert_ordering_deadline_text "12am Wednesday for Thursday pickup or 12am Friday for Saturday pickup"
  end

  test "dutch courage" do
    Setting.show_day2 = false
    Setting.pickup_day1 = "Monday"
    Setting.leadtime_hours = 12

    assert_day1_formatted "12pm Sunday"

    assert_ordering_deadline_text "12pm Sunday for Monday pickup"
  end

protected
  def assert_day1_formatted(text)
    assert_equal text, @menu.day1_deadline.strftime("%l%P %A").strip
  end

  def assert_day2_formatted(text)
    assert_equal text, @menu.day2_deadline.strftime("%l%P %A").strip
  end

  def assert_ordering_deadline_text(text)
    assert_equal text, ordering_deadline_text
  end

end
