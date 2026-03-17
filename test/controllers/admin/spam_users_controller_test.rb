require 'test_helper'

class Admin::SpamUsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/spam_users'
    assert_response :success
  end
end
