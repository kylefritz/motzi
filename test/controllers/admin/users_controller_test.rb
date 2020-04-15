require 'test_helper'

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/users'
    assert_response :success
  end

  test "get show" do
    obj = users(:kyle)
    get "/admin/users/#{obj.id}"
    assert_response :success
  end

  test "get edit" do
    obj = users(:kyle)
    get "/admin/users/#{obj.id}/edit"
    assert_response :success
  end

  test "post resend email" do
    obj = users(:kyle)
    assert_difference('MenuMailer.deliveries.count', 1) do
      post "/admin/users/#{obj.id}/resend_menu"
    end
    assert_response :redirect
  end
end
