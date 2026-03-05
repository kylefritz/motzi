require "test_helper"

class Admin::MissionControlJobsAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "admin can access jobs monitor" do
    sign_in users(:kyle)

    get "/jobs"
    follow_redirect! if response.redirect?

    assert_response :success
    assert_select "a", text: "Back to main app"
  end

  test "non-admin user cannot access jobs monitor" do
    sign_in users(:ljf)

    get "/jobs"

    assert_response :not_found
  end
end
