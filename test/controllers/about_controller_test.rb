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
end
