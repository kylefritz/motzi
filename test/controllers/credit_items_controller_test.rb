require "test_helper"

class CreditItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include StripeStubs

  setup do
    sign_in users(:ljf)
    menus(:week2).make_current!
    travel_to(Menu.current.earliest_deadline - 2.hours)
    stub_payment_intent_create
  end

  teardown { travel_back }

  test "can create credit items from consumer front end" do
    order_attrs = {
      price: 10.25,
      credits: 20,
      breads_per_week: 1.0,
      confirmation_token_id: stripe_confirmation_token
    }

    assert_difference "CreditItem.count", 1, "order created" do
      post "/credit_items.json", params: order_attrs, as: :json
      assert_response :success
    end

    validate_json_schema :credit_item, JSON.load(@response.body)

    new_credit_item = CreditItem.last
    assert_equal order_attrs[:credits], new_credit_item.quantity
    refute_nil new_credit_item.stripe_charge_id
    assert_equal created_payment_intent[:id], new_credit_item.stripe_payment_intent_id
    assert_equal order_attrs[:price], new_credit_item.stripe_charge_amount
    assert_equal "20x credits. Paid via Stripe $10.25.", new_credit_item.memo

    # The payment Stripe was asked for matches what the member paid.
    assert_requested :post, StripeStubs::STRIPE_PAYMENT_INTENTS_URL do |request|
      posted = Rack::Utils.parse_nested_query(request.body)
      posted["amount"] == "1025" && posted["confirmation_token"] == stripe_confirmation_token &&
        posted["metadata"]["kind"] == "credits" && posted["metadata"]["purchase_credits"] == "20" &&
        posted["metadata"]["purchase_user_id"] == users(:ljf).id.to_s
    end
  end

  test "declined card creates nothing and returns the decline message" do
    stub_stripe_card_declined
    order_attrs = { price: 10.25, credits: 20, breads_per_week: 1.0, confirmation_token_id: stripe_confirmation_token }

    assert_no_difference "CreditItem.count" do
      post "/credit_items.json", params: order_attrs, as: :json
      assert_response :unprocessable_content
    end

    assert_equal "Your card was declined.", response.parsed_body["message"]
  end

  test "a request Stripe rejects is reported and shown as a friendly error" do
    order_attrs = { price: 10.25, credits: 20, breads_per_week: 1.0, confirmation_token_id: stripe_confirmation_token }
    %w[invalid_request_error idempotency_error].each do |type|
      stub_stripe_request_rejected(type: type)
      assert_no_difference "CreditItem.count" do
        assert_difference "ErrorEvent.count", 1 do
          post "/credit_items.json", params: order_attrs, as: :json
        end
      end
      assert_response :unprocessable_content
      assert_equal "Something went wrong with your payment. Please try again.", response.parsed_body["message"]
    end
  end

  test "a card that needs 3D Secure adds credits once the payment intent is posted back" do
    stub_payment_intent_create(status: "requires_action", id: "pi_test_credits")
    order_attrs = { price: 46, credits: 6, breads_per_week: 0.5, confirmation_token_id: stripe_confirmation_token }

    assert_no_difference "CreditItem.count" do
      post "/credit_items.json", params: order_attrs, as: :json
    end
    assert_response :success
    assert_equal true, response.parsed_body["requiresAction"]
    assert_equal "pi_test_credits_secret_test", response.parsed_body["clientSecret"]

    stub_payment_intent_retrieve
    resume = order_attrs.except(:confirmation_token_id).merge(payment_intent_id: "pi_test_credits")

    # paying for more credits than were bought is rejected
    assert_no_difference "CreditItem.count" do
      post "/credit_items.json", params: resume.merge(credits: 26), as: :json
    end
    assert_response :unprocessable_content

    assert_difference "CreditItem.count", 1 do
      post "/credit_items.json", params: resume, as: :json
      assert_response :success
    end
    assert_equal "pi_test_credits", CreditItem.last.stripe_payment_intent_id
    assert_equal 6, CreditItem.last.quantity

    # posting it back again (a retry) doesn't add the credits twice
    assert_no_difference "CreditItem.count" do
      post "/credit_items.json", params: resume, as: :json
      assert_response :success
    end
  end

  test "another member can't claim a payment intent" do
    stub_payment_intent_create(status: "requires_action", id: "pi_test_credits")
    order_attrs = { price: 46, credits: 6, breads_per_week: 0.5, confirmation_token_id: stripe_confirmation_token }
    post "/credit_items.json", params: order_attrs, as: :json
    stub_payment_intent_retrieve

    sign_in users(:kyle)
    assert_no_difference "CreditItem.count" do
      post "/credit_items.json", params: order_attrs.except(:confirmation_token_id).merge(payment_intent_id: "pi_test_credits"),
                                 as: :json
    end
    assert_response :unprocessable_content
  end
end
