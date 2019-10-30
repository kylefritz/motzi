class MenuControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    week2 = menus(:week2)
    week2.make_current!
  end

  def assert_menu_json
    json  = @response.body
    assert json =~ /Rye Five Ways/, 'items serialized'
    assert json =~ /Donuts/, 'items serialized'
    assert json =~ /isAddOn/, 'isAddOn serialized'
    assert json =~ /bakersNote/, 'bakersNote'
    menu = JSON.load(json)
    
    validate_json_schema :menu, json
  end

  test "should get menu if signed in" do
    sign_in users(:ljf)
    get '/menu.json'
    assert_response :success

    assert_menu_json
  end

  test "should get menu if hashid" do
    ljf = users(:ljf)

    get "/menu.json?uid=#{ljf.hashid}"
    assert_response :success

    assert_menu_json
  end

  test "no menu otherwise" do
    get "/menu.json"
    assert_response :unauthorized
  end
end
