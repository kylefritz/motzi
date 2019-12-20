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
    if ENV.include?('GITHUB_ACTIONS')
      skip "skipping /admin/users/:id test on GH because we don't have webpacker setup"
    end
    obj = users(:kyle)
    get "/admin/users/#{obj.id}"
    assert_response :success
  end

  test "get edit" do
    obj = users(:kyle)
    get "/admin/users/#{obj.id}/edit"
    assert_response :success
  end
end
