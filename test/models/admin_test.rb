require 'test_helper'

class AdminTest < ActiveSupport::TestCase
  test "maya's password is wine" do
    maya = admins(:maya)
    assert maya.authenticate('wine')
  end
end
