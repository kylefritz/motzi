require "test_helper"
require "minitest/mock"

class MarketPlaceTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include StripeStubs

  setup do
    menus(:week2).make_current!
    travel_to(Menu.current.earliest_deadline - 2.hours)
    stub_payment_intent_create
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
    assert_equal created_payment_intent[:id], new_order.stripe_payment_intent_id
    assert_equal "https://pay.stripe.com/receipts/test_receipt", new_order.stripe_receipt_url

    # The charge Stripe was asked for matches the cart total, in cents.
    assert_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL do |request|
      posted = Rack::Utils.parse_nested_query(request.body)
      posted["amount"] == "1000" && posted["currency"] == "usd" &&
        posted["confirmation_token"] == stripe_confirmation_token && posted["confirm"] == "true" &&
        posted["receipt_email"] == order_attrs[:email] && posted["metadata"]["kind"] == "order"
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
    order_attrs[:confirmation_token_id] = nil
    assert_user_created { assert_ordered_emailed(order_attrs) }

    new_order = Order.last
    assert_nil new_order.stripe_charge_id
    assert_equal 0, new_order.stripe_charge_amount
    assert_not_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL
  end

  test "missing card payment" do
    order_attrs = build_order_attrs
    order_attrs[:confirmation_token_id] = nil
    refute_order(order_attrs)
    assert_equal "Stripe credit card not submitted", response.parsed_body["message"]
    assert_not_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL
  end

  test "credit card declined" do
    stub_stripe_card_declined
    order_attrs = build_order_attrs
    refute_order(order_attrs)
    assert_equal "Your card was declined.", response.parsed_body["message"]
  end

  test "below Stripe's 50 cent minimum is rejected before calling Stripe" do
    order_attrs = build_order_attrs.merge(price: 0.25)
    refute_order(order_attrs)
    assert_equal "Card payments must be at least $0.50", response.parsed_body["message"]
    assert_not_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL
  end

  #
  # PaymentIntents and 3D Secure (#412)
  #

  test "the payment intent is idempotent on the confirmation token and describes the purchase" do
    assert_user_created { assert_ordered_emailed(build_order_attrs) }

    assert_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL,
                     headers: { "Idempotency-Key" => "motzi-order-#{stripe_confirmation_token}" } do |request|
      posted = Rack::Utils.parse_nested_query(request.body)
      metadata = posted["metadata"]
      posted["payment_method_types"] == { "0" => "card" } &&
        metadata["purchase_menu_id"] == menus(:week2).id.to_s &&
        StripeCheckout.decode_cart(metadata["purchase_cart"]).map { |l| l[:item_id] } == [ items(:classic).id, items(:rye).id ] &&
        metadata["email"] == "jeff@jeff.com" && !metadata.key?("user_id")
    end
  end

  test "a card that needs 3D Secure saves nothing and returns the client secret" do
    stub_payment_intent_create(status: "requires_action", id: "pi_test_3ds")

    refute_user_created do
      refute_ordered do
        refute_emails_sent do
          post "/orders.json", params: build_order_attrs, as: :json
        end
      end
    end

    assert_response :success
    assert_equal true, response.parsed_body["requiresAction"]
    assert_equal "pi_test_3ds_secret_test", response.parsed_body["clientSecret"]
  end

  test "posting back a paid payment intent after 3D Secure places the order" do
    stub_payment_intent_create(status: "requires_action", id: "pi_test_3ds")
    post "/orders.json", params: build_order_attrs, as: :json
    stub_payment_intent_retrieve

    order_attrs = build_order_attrs.except(:confirmation_token_id).merge(payment_intent_id: "pi_test_3ds")
    assert_user_created { assert_ordered_emailed(order_attrs) }

    order = Order.last
    assert_equal "pi_test_3ds", order.stripe_payment_intent_id
    assert_equal "ch_test_3ds", order.stripe_charge_id
    assert_equal 10, order.stripe_charge_amount
    assert_equal "jeff@jeff.com", order.user.email
    assert_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL, times: 1
  end

  test "after 3D Secure the order is recorded from the payment, not from what's posted back" do
    stub_payment_intent_create(status: "requires_action", id: "pi_test_3ds")
    post "/orders.json", params: build_order_attrs, as: :json
    stub_payment_intent_retrieve

    tampered = build_order_attrs.except(:confirmation_token_id)
                                .merge(payment_intent_id: "pi_test_3ds", price: 1,
                                       cart: [ { item_id: items(:rye).id, quantity: 9, pickup_day_id: pickup_days(:w2_d1_thurs).id } ])
    assert_user_created { assert_ordered_emailed(tampered) }

    order = Order.last
    assert_equal 10, order.stripe_charge_amount
    assert_equal [ [ items(:classic).id, 1 ], [ items(:rye).id, 1 ] ].sort,
                 order.order_items.map { |oi| [ oi.item_id, oi.quantity ] }.sort
  end

  test "a payment intent can't be posted back by someone else, for another kind, or before it's paid" do
    stub_payment_intent_create(status: "requires_action", id: "pi_test_3ds")
    post "/orders.json", params: build_order_attrs, as: :json
    stub_payment_intent_retrieve
    resume = build_order_attrs.except(:confirmation_token_id).merge(payment_intent_id: "pi_test_3ds")

    refute_order(resume.merge(email: "someone.else@example.com"))
    assert_equal "We couldn't confirm your payment. Please try again.", response.parsed_body["message"]

    # a credit purchase's payment can't pay for an order
    stub_payment_intent_retrieve(metadata: created_payment_intent[:metadata].merge("kind" => "credits"))
    refute_order(resume)

    # nor can one that isn't paid yet, or was refunded
    stub_payment_intent_retrieve(status: "requires_action")
    refute_order(resume)
    intent = stub_payment_intent_retrieve
    stub_payment_intent_retrieve(latest_charge: intent[:latest_charge].merge(refunded: true, amount_refunded: 1000))
    refute_order(resume)
  end

  test "a payment still processing records nothing yet and says so" do
    stub_payment_intent_create(status: "processing", id: "pi_test_processing")
    refute_user_created do
      refute_ordered { post "/orders.json", params: build_order_attrs, as: :json }
    end
    assert_response :accepted
    assert_equal true, response.parsed_body["pending"]
    assert_match(/processing/, response.parsed_body["message"])

    # the same goes for one posted back after 3D Secure
    stub_payment_intent_retrieve(status: "processing")
    refute_ordered do
      post "/orders.json", params: build_order_attrs.except(:confirmation_token_id).merge(payment_intent_id: "pi_test_processing"),
                           as: :json
    end
    assert_response :accepted
  end

  test "a 3D Secure payment finished after the ordering deadline is still recorded" do
    stub_payment_intent_create(status: "requires_action", id: "pi_test_late")
    post "/orders.json", params: build_order_attrs, as: :json
    stub_payment_intent_retrieve

    travel_to(Menu.current.latest_deadline + 1.minute) do
      assert_user_created do
        assert_ordered_emailed(build_order_attrs.except(:confirmation_token_id).merge(payment_intent_id: "pi_test_late"))
      end
    end
    assert Order.exists?(stripe_payment_intent_id: "pi_test_late")
  end

  test "a payment_intent_id doesn't let an order skip its item limits" do
    menu_item_pickup_days(:w2_rye_thurs).update!(limit: 0)
    stub_stripe_request_rejected(method: :get, url: %r{\A#{StripeStubs::STRIPE_PAYMENT_INTENTS_URL}/pi_made_up})
    cart = [ { item_id: items(:rye).id, quantity: 5, pickup_day_id: pickup_days(:w2_d1_thurs).id } ]

    refute_ordered do
      post "/orders.json", params: { comments: "rye", uid: users(:ljf).hashid, cart: cart }, as: :json
    end
    assert_response :unprocessable_content
    assert_match(/sold out/, response.parsed_body["message"])

    # a made-up intent id sends it down the paid path, which finds no payment
    refute_ordered do
      post "/orders.json", params: { comments: "rye", uid: users(:ljf).hashid, payment_intent_id: "pi_made_up", cart: cart },
                           as: :json
    end
    assert_response :unprocessable_content
  end

  test "paying as a guest with a member's email doesn't hand back their account" do
    member = users(:ljf)
    assert_ordered_emailed(build_order_attrs.merge(email: member.email))

    body = response.parsed_body
    assert_nil body["user"], "the member's hashid signs in as them"
    assert_equal member.id, Order.last.user_id
  end

  test "a new guest gets their own account back" do
    assert_ordered_emailed(build_order_attrs)
    assert_equal "jeff@jeff.com", response.parsed_body.dig("user", "email")
  end

  test "a page loaded before PaymentIntents (posting a card token) is asked to reload" do
    stale = build_order_attrs.except(:confirmation_token_id).merge(token: "tok_visa")
    refute_order(stale)
    assert_equal "Please reload the page and try again.", response.parsed_body["message"]
    assert_not_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL
  end

  test "the price is rounded once, in BigDecimal: $9.995 meets a $10 minimum and is charged $10.00" do
    menu_items(:w2_classic).update!(pay_what_you_can: false)
    menu_items(:w2_rye).update!(pay_what_you_can: false)
    assert_user_created { assert_ordered_emailed(build_order_attrs.merge(price: "9.995")) }

    assert_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL do |request|
      Rack::Utils.parse_nested_query(request.body)["amount"] == "1000"
    end
  end

  test "a long comment is capped in the payment's metadata but kept on the order" do
    comments = "x" * 30_000
    assert_user_created { assert_ordered_emailed(build_order_attrs.merge(comments: comments)) }

    assert_equal comments, Order.last.comments
    assert_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL do |request|
      metadata = Rack::Utils.parse_nested_query(request.body)["metadata"]
      metadata.size <= StripeCheckout::METADATA_KEY_LIMIT &&
        StripeCheckout.read_metadata(metadata, "comments").length == OrdersController::COMMENTS_METADATA_LIMIT
    end
  end

  test "a guest who opted into the mailing list is subscribed only once their order commits" do
    subscribed = []
    MailerliteSubscriber.stub(:subscribe, ->(user) { subscribed << user.email; [ true, "subscribed" ] }) do
      stub_payment_intent_create(status: "requires_action", id: "pi_test_3ds")
      post "/orders.json", params: build_order_attrs.merge(mailing_list: true), as: :json
      assert_empty subscribed, "a guest rolled back for 3D Secure isn't subscribed"

      stub_payment_intent_retrieve
      post "/orders.json", params: build_order_attrs.except(:confirmation_token_id)
                                                    .merge(mailing_list: true, payment_intent_id: "pi_test_3ds"), as: :json
      assert_response :success
    end
    assert_equal [ "jeff@jeff.com" ], subscribed
  end

  test "posting back a payment the webhook already recorded returns that order" do
    stub_payment_intent_create(status: "requires_action", id: "pi_test_3ds")
    post "/orders.json", params: build_order_attrs, as: :json
    intent = stub_payment_intent_retrieve
    recorded = StripeCheckout::Fulfillment.record!(Stripe::PaymentIntent.construct_from(intent))

    assert_no_difference [ "Order.count", "User.count" ] do
      post "/orders.json", params: build_order_attrs.except(:confirmation_token_id).merge(payment_intent_id: "pi_test_3ds"),
                           as: :json
    end
    assert_response :success
    assert_equal recorded.id, response.parsed_body["order"]["id"]
  end

  test "a request Stripe rejects is reported and shown as a friendly error" do
    %w[invalid_request_error idempotency_error].each do |type|
      stub_stripe_request_rejected(type: type)
      assert_difference "ErrorEvent.count", 1 do
        refute_order(build_order_attrs)
      end
      assert_equal "Something went wrong with your payment. Please try again.", response.parsed_body["message"]
    end
  end

  test "an unknown payment intent posted back is a friendly error" do
    stub_stripe_request_rejected(method: :get, url: %r{\A#{StripeStubs::STRIPE_PAYMENT_INTENTS_URL}/pi_unknown})
    refute_order(build_order_attrs.except(:confirmation_token_id).merge(payment_intent_id: "pi_unknown"))
    assert_equal "Something went wrong with your payment. Please try again.", response.parsed_body["message"]
  end

  #
  # per-item pay what you can (#412). The cart is classic + rye at $5 each.
  #

  test "paying less than the fixed-price items is rejected" do
    menu_items(:w2_rye).update!(pay_what_you_can: false)
    order_attrs = build_order_attrs
    order_attrs[:price] = 4.99
    refute_order(order_attrs)
    assert_equal "The minimum for this order is $5.00 (Rye Five Ways is a fixed price)",
                 response.parsed_body["message"]
    assert_not_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL
  end

  test "a $0 order with a fixed-price item is rejected" do
    menu_items(:w2_rye).update!(pay_what_you_can: false)
    order_attrs = build_order_attrs.merge(price: 0, confirmation_token_id: nil)
    refute_order(order_attrs)
    assert_equal "The minimum for this order is $5.00 (Rye Five Ways is a fixed price)",
                 response.parsed_body["message"]
  end

  test "a guest can't skip the minimum by leaving the price off" do
    menu_items(:w2_rye).update!(pay_what_you_can: false)
    order_attrs = build_order_attrs.except(:price, :confirmation_token_id)
    refute_order(order_attrs)
    assert_equal "The minimum for this order is $5.00 (Rye Five Ways is a fixed price)",
                 response.parsed_body["message"]
  end

  test "paying exactly the minimum is ok; the pay what you can item goes to $0" do
    menu_items(:w2_rye).update!(pay_what_you_can: false)
    order_attrs = build_order_attrs
    order_attrs[:price] = 5
    assert_user_created { assert_ordered_emailed(order_attrs) }

    assert_equal 5, Order.last.stripe_charge_amount
    assert_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL do |request|
      Rack::Utils.parse_nested_query(request.body)["amount"] == "500"
    end
  end

  test "the cap sits above the minimum so a large fixed-price order can be paid" do
    menu_items(:w2_rye).update!(pay_what_you_can: false)
    order_attrs = build_order_attrs
    order_attrs[:cart] = [ { item_id: items(:rye).id, quantity: 60, pickup_day_id: pickup_days(:w2_d1_thurs).id } ]
    order_attrs[:price] = 300
    assert_user_created { assert_ordered_emailed(order_attrs) }

    assert_equal 300, Order.last.stripe_charge_amount
  end

  test "with the shop's pay what you can off, the full price is required" do
    shop = ActiveSupport::InheritableOptions.new(Setting.shop).tap { |s| s.pay_what_you_can = false }
    Setting.stub(:shop, -> { shop }) do
      order_attrs = build_order_attrs
      order_attrs[:price] = 9.99
      refute_order(order_attrs)
      assert_equal "The minimum for this order is $10.00 (Classic and Rye Five Ways are fixed prices)",
                   response.parsed_body["message"]

      assert_user_created { assert_ordered_emailed(build_order_attrs) }
      assert_equal 10, Order.last.stripe_charge_amount
    end
  end

  test "members paying with credits aren't held to fixed prices" do
    menu_items(:w2_rye).update!(pay_what_you_can: false)
    sign_in users(:jess)
    assert_ordered do
      post "/orders.json", params: build_order_attrs.except(:email, :first_name, :last_name, :phone, :price, :confirmation_token_id),
                           as: :json
    end
    assert_response :success
    assert_nil Order.last.stripe_charge_amount
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
      confirmation_token_id: stripe_confirmation_token
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
