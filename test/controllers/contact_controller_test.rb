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

  test "renders bakery address, phone, and hours" do
    get "/contact"
    assert_select "h1", text: /Contact Us/i
    assert_select "address", text: /2801 Guilford Ave/
    assert_match /443-272-1515/, @response.body
    assert_match /Tues.*Sat/i, @response.body
  end
end
