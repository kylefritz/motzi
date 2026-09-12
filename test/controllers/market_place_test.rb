require "test_helper"

class MarketPlaceTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include StripeStubs

  setup do
    menus(:week2).make_current!
    travel_to(Menu.current.earliest_deadline - 2.hours)
    stub_stripe_charge
  end

  teardown { travel_back }

  test "new, not logged in user can pay for order" do
    order_attrs = build_order_attrs
    assert_user_created { assert_ordered_emailed(order_attrs) }

    new_user = User.unscoped.order("created_at desc").last
    assert_equal order_attrs[:email], new_user.email
    assert_equal order_attrs[:first_name], new_user.first_name
    assert_equal order_attrs[:last_name], new_user.last_name
    assert_equal order_attrs[:phone], new_user.phone
    refute new_user.receive_weekly_menu?, "created user doesn't receive weekly menu"

    new_order = Order.last
    refute_nil new_order.stripe_charge_id
    refute_nil new_order.stripe_charge_amount

    # The charge Stripe was asked for matches the cart total, in cents.
    assert_requested :post, StripeStubs::STRIPE_CHARGES_URL do |request|
      posted = Rack::Utils.parse_nested_query(request.body)
      posted["amount"] == "1000" && posted["currency"] == "usd" &&
        posted["source"] == stripe_test_token &&
        posted["receipt_email"] == order_attrs[:email]
    end

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

  test "set mailing_list" do
    order_attrs = build_order_attrs
    order_attrs[:mailing_list] = true
    assert_user_created { assert_ordered_emailed(order_attrs) }

    new_user = User.unscoped.order("created_at desc").last
    assert new_user.mailing_list?, "should be on mailing list"
  end

  test "$0 price is ok" do
    order_attrs = build_order_attrs
    order_attrs[:price] = 0
    order_attrs[:token] = nil
    assert_user_created { assert_ordered_emailed(order_attrs) }

    new_order = Order.last
    assert_nil new_order.stripe_charge_id
    assert_equal 0, new_order.stripe_charge_amount
    assert_not_requested :post, StripeStubs::STRIPE_CHARGES_URL
  end

  test "missing stripe token" do
    order_attrs = build_order_attrs
    order_attrs[:token] = nil
    refute_order(order_attrs)
    assert_equal "Stripe credit card not submitted", response.parsed_body["message"]
    assert_not_requested :post, StripeStubs::STRIPE_CHARGES_URL
  end

  test "credit card declined" do
    stub_stripe_card_declined
    order_attrs = build_order_attrs
    refute_order(order_attrs)
    assert_equal "Your card was declined.", response.parsed_body["message"]
  end

  private
  def build_order_attrs
    {
      cart: [
          { item_id: items(:classic).id, price: 5, quantity: 1, pickup_day_id: pickup_days(:w2_d1_thurs).id },
          { item_id: items(:rye).id, price: 5, quantity: 1, pickup_day_id: pickup_days(:w2_d1_thurs).id }
      ],
      comments: nil,
      email: "jeff@jeff.com",
      first_name: "Jef",
      last_name: "Fritz",
      phone: "555-123-4567",
      price: 10.00,
      mailing_list: false,
      token: stripe_test_token
    }
  end

  def assert_ordered_emailed(order_attrs)
    assert_ordered do
      assert_email_sent do
        post "/orders.json", params: order_attrs, as: :json
        assert_response :success
        json = JSON.load(response.body)
        validate_json_schema :menu, json
        refute_nil json["order"]
      end
    end
  end

  def refute_order(order_attrs)
    refute_user_created do
      refute_ordered do
        refute_emails_sent do
          post "/orders.json", params: order_attrs, as: :json
          assert_response :unprocessable_content
        end
      end
    end
  end

  def assert_user_created(&block)
    assert_difference "User.count", 1, "user created" do
      block.call
    end
  end

  def refute_user_created(&block)
    assert_no_difference "User.count" do
      block.call
    end
  end
end
