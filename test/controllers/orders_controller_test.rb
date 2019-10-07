class OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:ljf)
  end

  test "should create order" do
    item_id = Menu.current.items.first.id
    order_attrs = {comment: 'test order', feedback: 'last week was great', items: [item_id]}

    assert_difference 'Order.count', 1, 'order should be created' do
      post '/orders', params: order_attrs, as: :json
    end
    assert_response :success
  end
end