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
    assert_email_sent do
      post "/admin/users/#{obj.id}/resend_menu"
    end
    assert_response :redirect
  end

  test "delete user with orders is blocked" do
    obj = users(:kyle)
    assert obj.orders.any?, "fixture user should have orders"

    assert_no_difference "User.count" do
      delete "/admin/users/#{obj.id}"
    end
    assert_redirected_to "/admin/users"
    follow_redirect!
    assert_select ".flash_alert", text: /without orders/
  end

  test "batch delete only removes users without orders" do
    deletable = User.create!(
      email: "deletable@example.com",
      first_name: "Delete",
      last_name: "Me",
      password: "password123"
    )
    keep = users(:kyle)
    assert keep.orders.any?, "fixture user should have orders"

    assert_difference "User.count", -1 do
      delete "/admin/users/batch_action", params: {
        collection_selection: [deletable.id, keep.id]
      }
    end

    assert_redirected_to "/admin/users"
    assert_nil User.find_by(id: deletable.id)
    assert User.exists?(keep.id)
  end
end
