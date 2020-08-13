require "test_helper"

class DeadlineHelperTest < ActiveSupport::TestCase
  include DeadlineHelper

  test "motzi" do
    Setting.pickup_day1 = "Thursday"
    Setting.pickup_day2 = "Saturday"
    Setting.leadtime_days = 1.125

    menu = Menu.create!(week_id: Time.zone.now.week_id, name: "motzi")
    assert_equal "9:00 pm Tuesday", menu.day1_deadline.strftime("%l:%M %P %A").strip
    assert_equal "9:00 pm Thursday", menu.day2_deadline.strftime("%l:%M %P %A").strip

    assert_equal "9:00 pm Tuesday for Thursday pickup or 9:00 pm Thursday for Saturday pickup", ordering_deadline_text
  end

  test "jinji" do
    Setting.pickup_day1 = "Thursday"
    Setting.pickup_day2 = "Saturday"
    Setting.leadtime_days = 1

    menu = Menu.create!(week_id: Time.zone.now.week_id, name: "motzi")
    assert_equal "12:00 am Wednesday", menu.day1_deadline.strftime("%l:%M %P %A").strip
    assert_equal "12:00 am Friday", menu.day2_deadline.strftime("%l:%M %P %A").strip

    assert_equal "12:00 am Wednesday for Thursday pickup or 12:00 am Friday for Saturday pickup", ordering_deadline_text
  end

  test "dutch courage" do
    Setting.show_day2 = false
    Setting.pickup_day1 = "Monday"
    Setting.leadtime_days = 0.5

    menu = Menu.create!(week_id: Time.zone.now.week_id, name: "dc")
    assert_equal "12:00 pm Sunday", menu.day1_deadline.strftime("%l:%M %P %A")

    assert_equal "12:00 pm Sunday for Monday pickup", ordering_deadline_text
  end
end
