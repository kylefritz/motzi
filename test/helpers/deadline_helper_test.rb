require "test_helper"

class DeadlineHelperTest < ActiveSupport::TestCase
  include DeadlineHelper

  def setup
    @menu = menus(:week1)
    @menu.update!(week_id: Time.zone.now.week_id)
  end

  test "ordering_deadline_text" do
    assert_equal "Thu, Jan 3 at 3p — order by Tue, Jan 1 at 10p\nSat, Jan 5 at 8a — order by Thu, Jan 3 at 10p", ordering_deadline_text(@menu)
  end
end
