require 'test_helper'

class Admin::OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/orders'
    assert_response :success
  end

  test "get show" do
    obj = Menu.current.orders.first
    get "/admin/orders/#{obj.id}"
    assert_response :success
  end

  test "get edit" do
    obj = Menu.current.orders.first
    get "/admin/orders/#{obj.id}/edit"
    assert_response :success
  end
end
