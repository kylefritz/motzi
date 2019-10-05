require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "maya's password is wine" do
    maya = users(:maya)
    assert maya.authenticate('wine')
    assert maya.is_admin
  end
end
