require "test_helper"

class DeadlineHelperTest < ActiveSupport::TestCase
  include DeadlineHelper

  def setup
    @menu = menus(:week1)
    travel_to_week_id("19w46") do
      @menu.update!(week_id: Time.zone.now.week_id)
    end
  end

  test "ordering_deadline_text" do
    assert_equal "Thu 01/03 3p pickup (order by Tue 01/01 10p);\nSat 01/05 8a pickup (order by Thu 01/03 10p)", ordering_deadline_text(@menu)
  end
end
