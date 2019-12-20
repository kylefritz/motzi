require 'test_helper'

class Admin::CreditItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/credit_items'
    assert_response :success
  end

  test "get show" do
    ci = CreditItem.first
    get "/admin/credit_items/#{ci.id}"
    assert_response :success
  end

  test "get edit" do
    ci = CreditItem.first
    get "/admin/credit_items/#{ci.id}/edit"
    assert_response :success
  end
end
