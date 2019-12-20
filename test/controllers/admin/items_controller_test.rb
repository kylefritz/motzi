require 'test_helper'

class Admin::ItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/items'
    assert_response :success
  end

  test "get items.json" do
    get '/admin/items.json'
    assert_response :success
    json  = @response.body
    assert json =~ /Classic/, 'items serialized'
    assert json =~ /Baker's Choice/, 'items serialized'
    items = JSON.load(json)

    validate_json_schema :admin_items, json
  end

  test "get show" do
    obj = items(:classic)
    get "/admin/items/#{obj.id}"
    assert_response :success
  end

  test "get edit" do
    obj = items(:classic)
    get "/admin/items/#{obj.id}/edit"
    assert_response :success
  end
end
