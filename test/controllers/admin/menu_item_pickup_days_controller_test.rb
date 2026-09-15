require "test_helper"

class Admin::MenuItemPickupDaysControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:kyle)
  end

  test "get index" do
    get "/admin/menu_item_pickup_days"
    assert_response :success
  end

  test "get show" do
    get "/admin/menu_item_pickup_days/#{menu_item_pickup_days(:w1_classic_thurs).id}"
    assert_response :success
  end
end
