require "test_helper"

class Admin::MissionControlJobsAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "admin dashboard links to jobs monitor" do
    menus(:week1).make_current!
    sign_in users(:kyle)

    get "/admin/dashboard"
    assert_response :success
    assert_select "a[href='/jobs']"
  end

  test "non-admin user cannot access jobs monitor" do
    sign_in users(:ljf)

    get "/jobs"

    assert_response :not_found
  end
end
