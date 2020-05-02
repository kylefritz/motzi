require 'test_helper'

class OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  def setup
    menus(:week2).make_current!
  end

  test "signed in user can create order" do
    sign_in users(:ljf)
    assert_order_placed
  end

  test "user cant order past deadline" do
    sign_in users(:ljf)
    assert_no_order_placed date_time=Menu.current.deadline + 2.hours
    assert_response :unprocessable_entity
  end

  test "admin user can order past deadline" do
    sign_in users(:maya)
    assert_order_placed date_time=Menu.current.deadline + 2.hours
  end

  test "hashid user can create order" do
    assert_order_placed date_time=nil, params=order_attrs.merge(uid: users(:ljf).hashid)
  end

  test "unknown user cannot create order" do
    assert_no_order_placed
    assert_response :unauthorized
  end

  private

  def order_attrs
    item_id = Menu.current.items.first.id
    order_attrs = {comment: 'test order', feedback: 'last week was great', cart: [{item_id: item_id}]}
  end

  def assert_order_placed(date_time=nil, params=nil)
    date_time ||= Menu.current.deadline - 2.hours

    Timecop.freeze(date_time) do
      assert_difference 'Order.count', 1, 'order should be created' do
        post '/orders.json', params: (params || order_attrs), as: :json
        assert_response :success
      end
    end
  end

  def assert_no_order_placed(date_time=nil, params=nil)
    date_time ||= Menu.current.deadline - 2.hours

    Timecop.freeze(date_time) do
      assert_no_difference 'Order.count', 'order should NOT be created' do
        post '/orders.json', params: (params || order_attrs), as: :json
      end
    end
  end
end
