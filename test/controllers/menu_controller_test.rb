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

  test "GET /menu.json with no holiday menu returns holidayMenu null" do
    Setting.holiday_menu_id = nil
    get '/menu.json'
    assert_response :success
    json = JSON.parse(@response.body)
    assert_nil json['holidayMenu']
    assert_nil json['holidayOrder']
    validate_json_schema :menu, @response.body
  end

  test "GET /menu.json with active holiday menu returns holidayMenu" do
    holiday = menus(:passover_2026)
    Setting.holiday_menu_id = holiday.id
    get '/menu.json'
    assert_response :success
    json = JSON.parse(@response.body)
    assert_not_nil json['holidayMenu']
    assert_equal holiday.id, json['holidayMenu']['id']
    validate_json_schema :menu, @response.body
  ensure
    Setting.holiday_menu_id = nil
  end

  test "GET /menu.json signed in with placed holiday order returns holidayOrder" do
    holiday = menus(:passover_2026)
    Setting.holiday_menu_id = holiday.id
    sign_in users(:ljf)
    get '/menu.json'
    assert_response :success
    json = JSON.parse(@response.body)
    assert_not_nil json['holidayMenu']
    assert_not_nil json['holidayOrder'], 'ljf has the passover order fixture'
    validate_json_schema :menu, @response.body
  ensure
    Setting.holiday_menu_id = nil
  end

  private

  def assert_menu_json
    assert_response :success

    json  = @response.body
    assert json =~ /Rye Five Ways/, 'items serialized'
    assert json =~ /subscriberNote/, 'subscriberNote'
    menu = JSON.load(json)

    validate_json_schema :menu, json
  end
end
