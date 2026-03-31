require "test_helper"

class Admin::CreditBundlesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:kyle)
  end

  test "get index" do
    get "/admin/credit_bundles"
    assert_response :success
  end
end
