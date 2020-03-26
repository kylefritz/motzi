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

  test "get pickup list day1" do
    menus(:week1).make_current!
    get "/admin/menus/pickup_day1"
    assert_response :success
    assert_select '#orders tbody tr', 2, "num_day1=#{menus(:week1).orders.day1_pickup.count}"
  end

  test "no skips in pickup list" do
    menus(:week1).make_current!

    # make this order into a skip
    order = menus(:week1).orders.day1_pickup.first
    order.order_items.update_all(item_id: Item::SKIP_ID) 

    get "/admin/menus/pickup_day1"
    assert_response :success
    assert_select '#orders tbody tr', 1, "num_day1=#{menus(:week1).orders.day1_pickup.count}"
  end

  test "get pickup list thursday" do
    menus(:week1).make_current!
    get "/admin/menus/pickup_day2"
    assert_response :success
    assert_select '#orders tbody tr', 1, "num_day2=#{menus(:week1).orders.day2_pickup.count}"
  end

  test "get edit" do
    obj = menus(:week2)
    get "/admin/menus/#{obj.id}/edit"
    assert_response :success
  end

  test "assign a bakers choice for a user" do
    user = users(:adrian)

    assert_nil user.current_order, 'user hasnt ordered yet'
    order_params = {user_id: user.id, item_id: items(:classic).id}

    assert_difference 'Order.count', 1, 'order should be created' do
      post '/admin/menus/bakers_choice.json', params: order_params, as: :json
      assert_response :success
    end

    refute_nil user.current_order, 'now user has ordered'
    refute user.current_order.skip?, 'not skip'
  end
end
