require "test_helper"

class Admin::AuthTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "non-admin user is redirected from admin" do
    sign_in users(:ljf)
    get "/admin/dashboard"
    assert_response :redirect
  end

  test "unauthenticated user is redirected from admin" do
    get "/admin/dashboard"
    assert_response :redirect
  end
end
