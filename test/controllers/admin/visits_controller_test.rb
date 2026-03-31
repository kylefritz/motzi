require "test_helper"

class Admin::VisitsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:kyle)
  end

  test "get index" do
    get "/admin/visits"
    assert_response :success
  end
end
