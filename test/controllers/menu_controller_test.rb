class MenuControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:ljf)
  end

  test "should get menu" do
    week2 = menus(:week2)
    week2.make_current!

    get '/menu.json'
    assert_response :success

    json  = @response.body
    assert json =~ /Rye Five Ways/, 'items serialized'
    assert json =~ /Donuts/, 'items serialized'
    assert json =~ /isAddOn/, 'isAddOn serialized'
    assert json =~ /bakersNote/, 'bakersNote'
  end
end
