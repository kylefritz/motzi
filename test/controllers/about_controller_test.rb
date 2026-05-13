require 'test_helper'

class AboutControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "renders for logged-out visitor" do
    get "/about"
    assert_response :success
    assert_select "body.marketing"
  end

  test "renders for logged-in user" do
    sign_in users(:kyle)
    get "/about"
    assert_response :success
  end

  test "renders the Our Process heading and key sections" do
    get "/about"
    assert_select "h1", text: /Our Process/i
    assert_select "h2", text: /Local Sourcing/i
    assert_select "h2", text: /Fresh Milling/i
    assert_select "h2", text: /Long Fermentation/i
  end
end
