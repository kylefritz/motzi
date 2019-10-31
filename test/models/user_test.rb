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

  test "current order" do
    menus(:week2).make_current!
    assert_nil users(:ljf).current_order, 'shouldnt have an order'
    assert_equal users(:kyle).current_order, orders(:kyle_week2), 'has already ordered'
  end

  test "blank name" do
    email = "someone@bread.com"
    user = User.create!(email: email, password: "sadfsfsdf")
    assert_equal user.name, email, 'email is fallback for name'
  end
end
