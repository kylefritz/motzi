require "test_helper"
require "minitest/mock"

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  include StripeStubs

  setup do
    menus(:week2).make_current!
    travel_to(Menu.current.earliest_deadline - 2.hours)
    @previous_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = StripeStubs::WEBHOOK_SECRET
  end

  teardown do
    ENV["STRIPE_WEBHOOK_SECRET"] = @previous_secret
    travel_back
  end

  test "a bad signature is rejected" do
    payload, _ = signed_stripe_event(order_intent)
    _, forged = signed_stripe_event(order_intent, secret: "whsec_someone_else")

    assert_no_difference "Order.count" do
      post "/stripe/webhooks", params: payload, headers: { "Stripe-Signature" => forged, "Content-Type" => "application/json" }
    end
    assert_response :bad_request

    post "/stripe/webhooks", params: payload, headers: { "Content-Type" => "application/json" }
    assert_response :bad_request
  end

  test "without a webhook secret configured every event is rejected" do
    ENV["STRIPE_WEBHOOK_SECRET"] = nil
    payload, signature = signed_stripe_event(order_intent, secret: "")

    post_event(payload, signature)
    assert_response :bad_request
  end

  test "places the order a browser never came back for, once" do
    intent = order_intent
    stub_payment_intent_retrieve(intent)
    payload, signature = signed_stripe_event(intent)

    assert_difference [ "Order.count", "User.count" ], 1 do
      assert_emails 1 do
        perform_enqueued_jobs { post_event(payload, signature) }
      end
    end
    assert_response :ok

    order = Order.last
    assert_equal "pi_test_webhook", order.stripe_payment_intent_id
    assert_equal "ch_test_webhook", order.stripe_charge_id
    assert_equal 10, order.stripe_charge_amount
    assert_equal "please slice", order.comments
    assert_equal menus(:week2), order.menu
    assert_equal [ [ items(:classic).id, pickup_days(:w2_d1_thurs).id, 1 ], [ items(:rye).id, pickup_days(:w2_d1_thurs).id, 2 ] ].sort,
                 order.order_items.map { |oi| [ oi.item_id, oi.pickup_day_id, oi.quantity ] }.sort
    assert_equal [ "guest@example.com", "Webhook", "Guest" ], [ order.user.email, order.user.first_name, order.user.last_name ]

    # Stripe retries deliveries; a repeat changes nothing
    assert_no_difference [ "Order.count", "User.count" ] do
      assert_no_emails do
        perform_enqueued_jobs { post_event(payload, signature) }
      end
    end
    assert_response :ok
  end

  test "is a no-op when the browser already placed the order" do
    stub_payment_intent_create(status: "succeeded", id: "pi_test_browser")
    post "/orders.json", params: browser_order_attrs, as: :json
    assert_response :success
    stub_payment_intent_retrieve

    payload, signature = signed_stripe_event(created_payment_intent)
    assert_no_difference [ "Order.count", "User.count" ] do
      post_event(payload, signature)
    end
    assert_response :ok
    assert_equal 1, Order.where(stripe_payment_intent_id: "pi_test_browser").count
  end

  test "browser and webhook racing on one payment record one order" do
    stub_payment_intent_create(status: "succeeded", id: "pi_test_race")
    # The webhook commits its order (on its own connection) while the
    # browser's request is between charging the card and saving the order,
    # so the browser's insert hits the unique index.
    webhook = PG.connect(**ActiveRecord::Base.connection_db_config.configuration_hash
                                 .slice(:host, :port, :user, :password).merge(dbname: ActiveRecord::Base.connection.current_database))
    create_order = StripeCheckout::Fulfillment.method(:create_order!)
    racing_create_order = lambda do |**kwargs|
      webhook.exec_params(<<~SQL, [ kwargs[:menu].id, users(:kyle).id ])
        INSERT INTO orders (menu_id, user_id, stripe_payment_intent_id, stripe_charge_id, stripe_charge_amount, created_at, updated_at)
        VALUES ($1, $2, 'pi_test_race', 'ch_test_race', 10, now(), now())
      SQL
      create_order.call(**kwargs)
    end

    StripeCheckout::Fulfillment.stub(:create_order!, racing_create_order) do
      assert_no_difference "User.count" do
        post "/orders.json", params: browser_order_attrs, as: :json
      end
    end

    assert_response :success
    webhook_order = Order.find_by!(stripe_payment_intent_id: "pi_test_race")
    assert_equal webhook_order.id, response.parsed_body["order"]["id"]
    assert_equal 1, Order.where(stripe_payment_intent_id: "pi_test_race").count
  ensure
    webhook&.exec("DELETE FROM orders WHERE stripe_payment_intent_id = 'pi_test_race'")
    webhook&.close
  end

  test "adds credits a browser never came back for" do
    member = users(:ljf)
    intent = payment_intent_json(
      id: "pi_test_credits", status: "succeeded", amount: 4600,
      metadata: { kind: "credits", purchase_user_id: member.id.to_s, purchase_credits: "6", breads_per_week: "0.5",
                  email: member.email }
    )
    stub_payment_intent_retrieve(intent)
    payload, signature = signed_stripe_event(intent)

    assert_difference "member.credit_items.count", 1 do
      post_event(payload, signature)
    end
    assert_response :ok
    credit_item = member.credit_items.order(:id).last
    assert_equal [ 6, 46, "pi_test_credits" ], [ credit_item.quantity, credit_item.stripe_charge_amount, credit_item.stripe_payment_intent_id ]
    assert member.reload.receive_weekly_menu?

    assert_no_difference "CreditItem.count" do
      post_event(payload, signature)
    end
  end

  test "ignores payments it didn't make and other events" do
    intent = payment_intent_json(id: "pi_test_other", status: "succeeded", amount: 500, metadata: {})
    stub_payment_intent_retrieve(intent)

    assert_no_difference [ "Order.count", "CreditItem.count" ] do
      post_event(*signed_stripe_event(intent))
      assert_response :ok
      post_event(*signed_stripe_event(intent, type: "payment_intent.created"))
      assert_response :ok
    end
  end

  private

  def post_event(payload, signature)
    post "/stripe/webhooks", params: payload, headers: { "Stripe-Signature" => signature, "Content-Type" => "application/json" }
  end

  def order_intent
    day = pickup_days(:w2_d1_thurs).id
    cart = StripeCheckout.encode_cart([ { item_id: items(:classic).id, pickup_day_id: day, quantity: 1 },
                                        { item_id: items(:rye).id, pickup_day_id: day, quantity: 2 } ])
    payment_intent_json(
      id: "pi_test_webhook", status: "succeeded", amount: 1000,
      metadata: { kind: "order", purchase_menu_id: menus(:week2).id.to_s, purchase_cart: cart, email: "guest@example.com",
                  user_id: "0123456789", first_name: "Webhook", last_name: "Guest", phone: "555-0100",
                  mailing_list: "false", comments: "please slice" }
    )
  end

  def browser_order_attrs
    {
      cart: [ { item_id: items(:classic).id, quantity: 1, pickup_day_id: pickup_days(:w2_d1_thurs).id } ],
      email: "browser@example.com", first_name: "Browser", last_name: "Guest", phone: "555-0101",
      price: 10, confirmation_token_id: stripe_confirmation_token
    }
  end
end
