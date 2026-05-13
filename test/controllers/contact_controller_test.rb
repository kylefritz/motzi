require 'test_helper'

class ContactControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "show renders for logged-out visitor" do
    get "/contact"
    assert_response :success
    assert_select "body.marketing"
  end

  test "show renders for logged-in user" do
    sign_in users(:kyle)
    get "/contact"
    assert_response :success
  end
end
