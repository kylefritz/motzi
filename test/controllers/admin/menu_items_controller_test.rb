require 'test_helper'

class Admin::MenuItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/menu_items'
    assert_response :success
  end

  test "get show" do
    obj = Menu.current.menu_items.first
    get "/admin/menu_items/#{obj.id}"
    assert_response :success
  end

  test "get edit" do
    obj = Menu.current.menu_items.first
    get "/admin/menu_items/#{obj.id}/edit"
    assert_response :success
  end
end
