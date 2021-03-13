require 'test_helper'
require 'stripe_mock'

class MarketPlaceTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  def setup
    menus(:week2).make_current!
    travel_to(Menu.current.earliest_deadline - 2.hours)
    StripeMock.start
    @stripe_helper = StripeMock.create_test_helper
  end

  def teardown
    travel_back
    StripeMock.stop
  end

  test "new, not logged in user can pay for order" do
    order_attrs = build_order_attrs
    assert_user_created { assert_ordered_emailed(order_attrs) }

    new_user = User.unscoped.order("created_at desc").last
    assert_equal order_attrs[:email], new_user.email
    assert_equal order_attrs[:first_name], new_user.first_name
    assert_equal order_attrs[:last_name], new_user.last_name
    assert_equal order_attrs[:phone], new_user.phone
    refute new_user.subscriber?, "created user isn't a subscriber"

    new_order = Order.last
    refute_nil new_order.stripe_charge_id
    refute_nil new_order.stripe_charge_amount

    # after second order, no user created
    refute_user_created { assert_ordered_emailed(build_order_attrs) }
  end

  test "existing user (with an order) can place marketplace order" do
    order_attrs = build_order_attrs
    order_attrs[:email] = users(:kyle).email
    refute_user_created { assert_ordered_emailed(order_attrs) }

    new_order = Order.last
    refute_nil new_order.stripe_charge_id
    refute_nil new_order.stripe_charge_amount
  end


  test "marketplace order does not block existing user from placing subscription order" do
    kyle = users(:kyle)
    kyle.orders.delete_all
    assert_equal 0, kyle.orders.size

    order_attrs = build_order_attrs
    order_attrs[:email] = users(:kyle).email
    assert_ordered_emailed(order_attrs)

    get "/menu.json?uid=#{users(:kyle).hashid}"
    data = JSON.load(@response.body)
    assert_nil data["order"], "an order in menu json would block you from ordering again"
  end

  test "set opt_in" do
    order_attrs = build_order_attrs
    order_attrs[:opt_in] = true
    assert_user_created { assert_ordered_emailed(order_attrs) }

    new_user = User.unscoped.order("created_at desc").last
    assert new_user.opt_in?, "shouldn't get marketing emails"
  end

  test "$0 price is ok" do
    order_attrs = build_order_attrs
    order_attrs[:price] = 0
    order_attrs[:token] = nil
    assert_user_created { assert_ordered_emailed(order_attrs) }

    new_order = Order.last
    assert_nil new_order.stripe_charge_id
    assert_equal 0, new_order.stripe_charge_amount
  end

  test "missing stripe token" do
    order_attrs = build_order_attrs
    order_attrs[:token] = nil
    refute_order(order_attrs)
    assert_equal "Stripe credit card not submitted", response.parsed_body["message"]
  end

  test "credit card declined" do
    StripeMock.prepare_card_error(:card_declined)
    order_attrs = build_order_attrs
    refute_order(order_attrs)
    assert_equal "The card was declined", response.parsed_body["message"]
  end

  private
  def build_order_attrs
    return {
      cart: [
          {item_id: items(:classic).id, price: 5, quantity: 1, pickup_day_id: pickup_days(:w2_d1_thurs).id},
          {item_id: items(:rye).id, price: 5, quantity: 1, pickup_day_id: pickup_days(:w2_d1_thurs).id}
      ],
      comments: nil,
      email: "jeff@jeff.com",
      first_name: "Jef",
      last_name: "Fritz",
      phone: "555-123-4567",
      price: 10.00,
      opt_in: false,
      token: @stripe_helper.generate_card_token
    }
  end

  def assert_ordered_emailed(order_attrs)
    assert_ordered do
      assert_email_sent do
        post '/orders.json', params: order_attrs, as: :json
        assert_response :success
      end
    end
  end

  def refute_order(order_attrs)
    refute_user_created do
      refute_ordered do
        refute_emails_sent do
          post '/orders.json', params: order_attrs, as: :json
          assert_response :unprocessable_entity
        end
      end
    end
  end

  def assert_user_created(&block)
    assert_difference 'User.count', 1, 'user created' do
      block.call
    end
  end

  def refute_user_created(&block)
    assert_no_difference 'User.count' do
      block.call
    end
  end
end
