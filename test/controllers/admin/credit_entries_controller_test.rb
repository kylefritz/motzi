require 'test_helper'

class Admin::CreditEntriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/credit_entries'
    assert_response :success
  end

  test "get show" do
    ci = CreditEntry.first
    get "/admin/credit_entries/#{ci.id}"
    assert_response :success
  end

  test "get edit" do
    ci = CreditEntry.first
    get "/admin/credit_entries/#{ci.id}/edit"
    assert_response :success
  end
end
