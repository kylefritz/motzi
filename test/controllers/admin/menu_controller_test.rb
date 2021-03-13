require 'test_helper'

class Admin::MenuControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/menus'
    assert_response :success
  end

  test "get show" do
    obj = menus(:week2)
    get "/admin/menus/#{obj.id}"
    assert_response :success
  end

  test "get edit" do
    obj = menus(:week2)
    get "/admin/menus/#{obj.id}/edit"
    assert_response :success
  end

  test "get menu_items" do
    obj = menus(:week2)
    get "/admin/menus/#{obj.id}/menu_builder.json"
    assert_response :success

    validate_json_schema :admin_menu_builder, @response.body
  end
end
