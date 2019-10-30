class OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def order_attrs
    item_id = Menu.current.items.first.id
    order_attrs = {comment: 'test order', feedback: 'last week was great', items: [item_id]}
  end

  test "signed in user can create order" do
    sign_in users(:ljf)
    assert_difference 'Order.count', 1, 'order should be created' do
      post '/orders', params: order_attrs, as: :json
      assert_response :success
    end
    
  end

  test "hashid user can create order" do
    assert_difference 'Order.count', 1, 'order should be created' do
      post '/orders', params: order_attrs.merge(uid: users(:ljf).hashid), as: :json
      assert_response :success
    end
  end

  test "unknown user cannot create order" do
    assert_no_difference 'Order.count', 'order should NOT be created' do
      post '/orders', params: order_attrs, as: :json
      assert_response :unauthorized
    end
  end
end
