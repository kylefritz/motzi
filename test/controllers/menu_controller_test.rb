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

  test "should get menu if hashid" do
    get "/menu.json?uid=#{users(:ljf).hashid}"
    assert_menu_json
  end

  test "no menu otherwise" do
    get "/menu.json"
    assert_response :unauthorized
  end

  private

  def assert_menu_json
    assert_response :success

    json  = @response.body
    assert json =~ /Rye Five Ways/, 'items serialized'
    assert json =~ /Donuts/, 'items serialized'
    assert json =~ /isAddOn/, 'isAddOn serialized'
    assert json =~ /bakersNote/, 'bakersNote'
    menu = JSON.load(json)
    
    validate_json_schema :menu, json
  end

end
