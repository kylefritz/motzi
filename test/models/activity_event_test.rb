require 'test_helper'

class ActivityEventTest < ActiveSupport::TestCase
  test "ActivityEvent.log creates an event" do
    assert_difference "ActivityEvent.count", 1 do
      ActivityEvent.log(
        action: "menu_published",
        week_id: "26w10",
        description: "Menu emailed to 200 subscribers",
        metadata: {menu_id: 1, count: 200},
        user: users(:kyle)
      )
    end
    event = ActivityEvent.last
    assert_equal "menu_published", event.action
    assert_equal "26w10", event.week_id
    assert_equal 200, event.metadata["count"]
    assert_equal users(:kyle), event.user
  end

  test "validates required fields" do
    event = ActivityEvent.new
    refute event.valid?
    assert_includes event.errors[:action], "can't be blank"
    assert_includes event.errors[:week_id], "can't be blank"
    assert_includes event.errors[:description], "can't be blank"
  end

  test ".for_week scopes correctly" do
    ActivityEvent.log(action: "a", week_id: "26w10", description: "x")
    ActivityEvent.log(action: "b", week_id: "26w11", description: "y")
    assert_equal 1, ActivityEvent.for_week("26w10").count
    assert_equal 1, ActivityEvent.for_week("26w11").count
  end

  test ".log does not raise on failure" do
    result = ActivityEvent.log(action: nil, week_id: nil, description: nil)
    assert_nil result
  end

  test "user is optional" do
    event = ActivityEvent.log(
      action: "test",
      week_id: "26w10",
      description: "no user"
    )
    assert event.persisted?
    assert_nil event.user
  end
end
