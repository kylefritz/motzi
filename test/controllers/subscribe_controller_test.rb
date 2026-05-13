require 'test_helper'

class SubscribeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "renders for logged-out visitor" do
    get "/subscribe"
    assert_response :success
    assert_select "body.marketing"
  end

  test "renders for logged-in user" do
    sign_in users(:kyle)
    get "/subscribe"
    assert_response :success
  end

  test "renders subscription details and CTA to sign up" do
    get "/subscribe"
    assert_select "h1", text: /Subscriptions/i
    assert_select "a[href=?]", "/users/sign_up", text: /SUBSCRIBE NOW/i
  end
end
