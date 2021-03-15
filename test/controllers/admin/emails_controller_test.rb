require 'test_helper'

class Admin::EmailsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    MenuMailer.with(user: users(:kyle), menu: menus(:week2)).weekly_menu_email.deliver_now

    get '/admin/emails'
    assert_response :success
  end
end
