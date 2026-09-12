require "test_helper"

class CreditItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include StripeStubs

  setup do
    sign_in users(:ljf)
    menus(:week2).make_current!
    travel_to(Menu.current.earliest_deadline - 2.hours)
    stub_stripe_charge
  end

  teardown { travel_back }

  test "can create credit items from consumer front end" do
    order_attrs = {
      price: 10.25,
      credits: 20,
      breads_per_week: 1.0,
      token: stripe_test_token
    }

    assert_difference "CreditItem.count", 1, "order created" do
      post "/credit_items.json", params: order_attrs, as: :json
      assert_response :success
    end

    validate_json_schema :credit_item, JSON.load(@response.body)

    new_credit_item = CreditItem.last
    assert_equal order_attrs[:credits], new_credit_item.quantity
    refute_nil new_credit_item.stripe_charge_id
    refute_nil new_credit_item.stripe_charge_amount
    assert_equal order_attrs[:price], new_credit_item.stripe_charge_amount

    # The charge Stripe was asked for matches what the member paid.
    assert_requested :post, StripeStubs::STRIPE_CHARGES_URL do |request|
      posted = Rack::Utils.parse_nested_query(request.body)
      posted["amount"] == "1025" && posted["source"] == stripe_test_token &&
        posted["metadata"]["credits"] == "20"
    end
  end

  test "declined card creates nothing and returns the decline message" do
    stub_stripe_card_declined
    order_attrs = { price: 10.25, credits: 20, breads_per_week: 1.0, token: stripe_test_token }

    assert_no_difference "CreditItem.count" do
      post "/credit_items.json", params: order_attrs, as: :json
      assert_response :unprocessable_content
    end

    assert_equal "Your card was declined.", response.parsed_body["error"]
  end
end
