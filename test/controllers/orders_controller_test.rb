require 'test_helper'

class OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  def setup
    menus(:week2).make_current!
  end

  test "hashid_user can create order" do
    before_deadline do
      assert_order_placed users(:ljf).hashid
    end
  end

  test "hashid_user cant order past deadline" do
    after_deadline do
      refute_order_placed users(:ljf).hashid
    end
    assert_response :unprocessable_entity
  end

  test "hashid_user can update their own order" do
    before_deadline do
      assert_order_placed users(:ljf).hashid

      put_order users(:ljf).current_order.id, different_order_attrs(users(:ljf).hashid)
    end
    assert_response :success
  end

  test "hashid_user cannot update someone else's order" do
    before_deadline do
      assert_order_placed users(:ljf).hashid
      order = users(:ljf).current_order
      order.update(user: users(:jess))

      put_order order.id, different_order_attrs(users(:ljf).hashid)
    end
    assert_response :unauthorized
  end

  test "hashid_user cannot update their own order past deadline" do
    before_deadline do
      assert_order_placed users(:ljf).hashid
    end

    after_deadline do
      put_order users(:ljf).current_order.id, different_order_attrs(users(:ljf).hashid)
    end
    assert_response :unprocessable_entity
  end

  test "admin can update any order" do
    sign_in users(:maya)
    before_deadline do
      put_order Order.last.id, different_order_attrs
    end
    assert_response :success
  end

  test "admin can order past deadline" do
    sign_in users(:maya)
    after_deadline do
      assert_order_placed
    end
  end

  test "signed in user can create order" do
    sign_in users(:ljf)
    before_deadline do
      assert_order_placed
    end
  end

  test "unknown user cannot create order" do
    before_deadline do
      refute_order_placed
    end
    assert_response :unauthorized
  end

  private

  def order_attrs(hashid)
    item_id = Menu.current.items.first.id
    {comment: 'test order', cart: [{item_id: item_id}]}.tap do |attrs|
      attrs[:uid] = hashid if hashid
    end
  end

  def different_order_attrs(hashid=nil)
    item_id = items(:rye).id
    {comment: 'different', cart: [{item_id: item_id, quantity: 3}]}.tap do |attrs|
      attrs[:uid] = hashid if hashid
    end
  end

  def assert_order_placed(hashid=nil)
    assert_email_sent do
      assert_ordered do
        post '/orders.json', params: order_attrs(hashid), as: :json
        assert_response :success
      end
    end
  end

  def refute_order_placed(hashid=nil)
    refute_ordered do
      post '/orders.json', params: order_attrs(hashid), as: :json
    end
  end

  def put_order(order_id, params)
    put "/orders/#{order_id}.json", params: params, as: :json
  end

  def before_deadline(&block)
    travel_to(Menu.current.day1_deadline - 2.hours) do
      block.call
    end
  end

  def after_deadline(&block)
    travel_to(Menu.current.day2_deadline + 2.hours) do
      block.call
    end
  end
end
