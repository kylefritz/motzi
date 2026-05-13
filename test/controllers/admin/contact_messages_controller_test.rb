require 'test_helper'

class Admin::ContactMessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/contact_messages'
    assert_response :success
  end
end
