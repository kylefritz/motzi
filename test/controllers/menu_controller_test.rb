require 'test_helper'

class MenuControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
  end

  test "should get menu if signed in" do
    sign_in users(:ljf)
    get '/menu.json'
    assert_menu_json
  end

  test "should get menu & order once placed" do
    sign_in users(:ljf)
    order = orders(:ljf_week1)
    order.update(menu: Menu.current)
    get '/menu.json'
    assert_menu_json
  end

  test "should get menu if hashid" do
    get "/menu.json?uid=#{users(:ljf).hashid}"
    assert_menu_json
  end

  test "menu ok if no user" do
    get "/menu.json"
    assert_menu_json
  end

  test "get menu by id" do
    get "/menus/#{menus(:week2).id}.json"
    assert_menu_json
  end

  private

  def assert_menu_json
    assert_response :success

    json  = @response.body
    assert json =~ /"items"/, 'items serialized'
    assert json =~ /"openMenus"/, 'open menus'
    assert json =~ /"pickupDays"/, 'pickup days'
    assert json =~ /subscriberNote/, 'subscriberNote'
    menu = JSON.load(json)

    validate_json_schema :menu, json
  end
end
