require "test_helper"

class DeadlineHelperTest < ActiveSupport::TestCase
  include DeadlineHelper

  def setup
    @menu = menus(:week1)
    @menu.update!(week_id: Time.zone.now.week_id)
  end

  test "ordering_deadline_text" do
    assert_equal "for Thu 01/03 pickup: order by 10p on Tue 01/01 or for Sat 01/05 pickup: order by 10p on Thu 01/03", ordering_deadline_text(@menu).gsub(/\n/,' ')
  end
end
