require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
  end

  test "renders the marketing home for logged-out visitor" do
    get "/"
    assert_response :success
    assert_select "body.marketing"
    assert_select ".hero h1", text: /Community Bakery/i
    assert_select "h2", text: /Find Us Here/i
    assert_select "a.cta-primary[href=?]", "/subscribe"
  end

  test "renders the marketing home for logged-in user" do
    sign_in users(:kyle)
    get "/"
    assert_response :success
    assert_select "body.marketing"
  end

  test "signing in lands members on the menu, not the marketing home" do
    post user_session_path, params: { user: { email: users(:kyle).email, password: "robots" } }
    assert_redirected_to "/menu"
  end

  test "signout still works" do
    sign_in users(:kyle)
    get "/signout"
    assert_redirected_to "/"
  end
end
