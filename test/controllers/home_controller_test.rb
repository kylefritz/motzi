require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get home" do
    get '/'
    assert_redirected_to '/menu'
  end

  test "signout" do
    get "/signout"
    assert_redirected_to '/'
  end
end
