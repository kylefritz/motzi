require 'test_helper'

class OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  def setup
    menus(:week2).make_current!
    Timecop.freeze(Menu.current.deadline - 2.hours)
  end

  def teardown
    Timecop.return
  end

  test "hashid_user can create order" do
    assert_order_placed users(:ljf).hashid
  end

  test "hashid_user cant order past deadline" do
    Timecop.freeze(Menu.current.deadline + 2.hours) do
      assert_no_order_placed users(:ljf).hashid
      assert_response :unprocessable_entity
    end
  end

  test "hashid_user can update their own order" do
    assert_order_placed users(:ljf).hashid
    order_id = users(:ljf).current_order.id

    put "/orders/#{order_id}.json", params: different_order_attrs(users(:ljf).hashid), as: :json
    assert_response :success
  end

  test "hashid_user cannot update someone else's order" do
    assert_order_placed users(:ljf).hashid
    order = users(:ljf).current_order
    order.update(user: users(:jess))

    put "/orders/#{order.id}.json", params: different_order_attrs(users(:ljf).hashid), as: :json
    assert_response :unauthorized
  end

  test "hashid_user cannot update their own order past deadline" do
    assert_order_placed users(:ljf).hashid
    Timecop.freeze(Menu.current.deadline + 2.hours) do
      order_id = users(:ljf).current_order.id
      put "/orders/#{order_id}.json", params: different_order_attrs(users(:ljf).hashid), as: :json
      assert_response :unprocessable_entity
    end
  end

  test "admin can update any order" do
    sign_in users(:maya)
    order_id = Order.last.id
    put "/orders/#{order_id}.json", params: different_order_attrs, as: :json
    assert_response :success
  end

  test "admin can order past deadline" do
    sign_in users(:maya)
    Timecop.freeze(Menu.current.deadline + 2.hours) do
      assert_order_placed
    end
  end

  test "signed in user can create order" do
    sign_in users(:ljf)
    assert_order_placed
  end

  test "unknown user cannot create order" do
    assert_no_order_placed
    assert_response :unauthorized
  end

  private

  def order_attrs(hashid)
    item_id = Menu.current.items.first.id
    {comment: 'test order', feedback: 'last week was great', cart: [{item_id: item_id}]}.tap do |attrs|
      attrs[:uid] = hashid if hashid
    end
  end

  def different_order_attrs(hashid=nil)
    item_id = items(:rye).id
    {comment: 'different', feedback: 'different', cart: [{item_id: item_id, quantity: 3}]}.tap do |attrs|
      attrs[:uid] = hashid if hashid
    end
  end

  def assert_order_placed(hashid=nil)
    users(:ljf).hashid

    assert_difference 'Order.count', 1, 'order should be created' do
      post '/orders.json', params: order_attrs(hashid), as: :json
      assert_response :success
    end
  end

  def assert_no_order_placed(hashid=nil)
    assert_no_difference 'Order.count', 'order should NOT be created' do
      post '/orders.json', params: order_attrs(hashid), as: :json
    end
  end
end
