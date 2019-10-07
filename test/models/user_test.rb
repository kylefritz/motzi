require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "maya's password is wine" do
    maya = users(:maya)
    assert maya.authenticate('wine')
    refute maya.authenticate('not-wine')
    assert maya.is_admin
  end

  test "half of the week" do
    assert users(:kyle).is_first_half?
    refute users(:ljf).is_first_half?
  end

  test "credits remaining" do
    assert_equal users(:ljf).credits, 0
    assert_equal users(:kyle).credits, 23
  end
end
