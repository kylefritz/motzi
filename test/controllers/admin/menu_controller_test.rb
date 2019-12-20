require 'test_helper'

class Admin::MenuControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    menus(:week2).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get '/admin/menus'
    assert_response :success
  end

  test "get show" do
    obj = menus(:week2)
    get "/admin/menus/#{obj.id}"
    assert_response :success
  end

  test "get edit" do
    obj = menus(:week2)
    get "/admin/menus/#{obj.id}/edit"
    assert_response :success
  end

  test "assign a bakers choice for a user" do
    user = users(:adrian)
    
    assert_nil user.order_for_menu(Menu.current), 'user hasnt ordered yet'
    order_params = {user_id: user.id, item_id: items(:classic).id}

    assert_difference 'Order.count', 1, 'order should be created' do
      post '/admin/menus/bakers_choice.json', params: order_params, as: :json
      assert_response :success
    end
    
    refute_nil user.order_for_menu(Menu.current), 'now user has ordered'
    refute user.order_for_menu(Menu.current).skip?, 'not skip'
  end
end
