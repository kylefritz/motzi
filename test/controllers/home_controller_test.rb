require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "renders the marketing home for logged-out visitor" do
    get "/"
    assert_response :success
    assert_select "body.marketing"
    assert_select "h1, h2", text: /Community Bakery/i
  end

  test "renders the marketing home for logged-in user" do
    sign_in users(:kyle)
    get "/"
    assert_response :success
    assert_select "body.marketing"
  end

  test "signout still works" do
    sign_in users(:kyle)
    get "/signout"
    assert_redirected_to "/"
  end
end
