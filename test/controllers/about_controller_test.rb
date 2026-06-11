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

  test "shows admin nav link for admins only" do
    sign_in users(:kyle) # admin
    get "/about"
    assert_select "a[href=?]", "/admin"

    sign_in users(:ljf) # non-admin
    get "/about"
    assert_select "a[href=?]", "/admin", count: 0
  end

  test "renders the Our Process heading and key sections" do
    get "/about"
    assert_select "h1", text: /Our Process/i
    assert_select "h2", text: /Local Sourcing/i
    assert_select "h2", text: /Fresh Milling/i
    assert_select "h2", text: /Long\s*Fermentation/im
    assert_select "img[src*='motzi.s3.us-east-1.amazonaws.com']", minimum: 3
  end
end
