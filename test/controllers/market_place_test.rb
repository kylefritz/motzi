require 'test_helper'
require 'stripe_mock'

class MarketPlaceTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  def setup
    menus(:week2).make_current!
    Timecop.freeze(Menu.current.deadline - 2.hours)
    StripeMock.start
    @stripe_helper = StripeMock.create_test_helper
  end

  def teardown
    Timecop.return
    StripeMock.stop
  end

  test "not logged in user can pay for order" do
    order_attrs = build_order_attrs
    assert_order(order_attrs, 1, 1, 1)
    assert_response :success

    new_user = User.unscoped.order("created_at desc").last
    assert_equal order_attrs[:email], new_user.email
    refute new_user.subscriber?, "created user isn't a subscriber"
    refute new_user.send_weekly_email?, "shouldn't get weekly email"

    new_order = Order.last
    refute_nil new_order.stripe_charge_id
    refute_nil new_order.stripe_charge_amount

    # after second order, no user created
    assert_order(build_order_attrs, 1, 0, 1)
  end

  test "existing user can pay for order" do
    order_attrs = build_order_attrs
    order_attrs[:email] = users(:kyle).email
    assert_order(order_attrs, 1, 0, 1)
    assert_response :success

    new_order = Order.last
    refute_nil new_order.stripe_charge_id
    refute_nil new_order.stripe_charge_amount
  end

  test "missing stripe token" do
    order_attrs = build_order_attrs
    order_attrs[:token] = nil
    assert_order(order_attrs, 0, 0, 0)
    assert_response :unprocessable_entity
    assert_equal "Stripe credit card not submitted", response.parsed_body["message"]
  end

  test "credit card declined" do
    StripeMock.prepare_card_error(:card_declined)
    order_attrs = build_order_attrs
    assert_order(order_attrs, 0, 0, 0)
    assert_response :unprocessable_entity
    assert_equal "The card was declined", response.parsed_body["message"]
  end

  private
  def build_order_attrs
    return {
      cart: [
          {itemId: items(:classic).id, price: 5, quantity: 1, day: "Thursday"},
          {itemId: items(:rye).id, price: 5, quantity: 1, day: "Thursday"}
      ],
      comments: nil,
      email: "jeff@jeff.com",
      firstName: "Jef",
      lastName: "Fritz",
      price: 10.00,
      token: @stripe_helper.generate_card_token
    }
  end

  def assert_order(order_attrs, num_orders, num_users, num_emails)
    assert_difference 'Order.count', num_orders, 'order created' do
      assert_difference 'User.count', num_users, 'user created' do
        assert_emails_sent(num_emails) do
          post '/orders.json', params: order_attrs, as: :json
        end
      end
    end
  end

end
