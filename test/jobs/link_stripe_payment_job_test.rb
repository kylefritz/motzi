require "test_helper"

class LinkStripePaymentJobTest < ActiveJob::TestCase
  include StripeStubs

  setup do
    @order = orders(:kyle_week1)
    @order.update!(stripe_payment_intent_id: "pi_test_link_order", stripe_charge_id: "ch_test_link_order", stripe_charge_amount: 10)
    @credit_item = credit_items(:kyle)
    @credit_item.update!(stripe_payment_intent_id: "pi_test_link_credits", stripe_charge_id: "ch_test_link_credits", quantity: 6)
  end

  test "names the order on its payment intent" do
    stub_payment_intent_update

    LinkStripePaymentJob.perform_now(@order)

    assert_requested :post, "#{STRIPE_PAYMENT_INTENTS_URL}/pi_test_link_order" do |request|
      posted = Rack::Utils.parse_nested_query(request.body)
      posted["description"] == "Order ##{@order.id} - #{@order.menu.name} - #{@order.item_list}" &&
        posted["metadata"] == { "order_id" => @order.id.to_s }
    end
  end

  test "names the credit item on its payment intent" do
    stub_payment_intent_update

    LinkStripePaymentJob.perform_now(@credit_item)

    assert_requested :post, "#{STRIPE_PAYMENT_INTENTS_URL}/pi_test_link_credits" do |request|
      posted = Rack::Utils.parse_nested_query(request.body)
      posted["description"] == "Credits ##{@credit_item.id} - #{StripeCheckout::Fulfillment.credits_description(6)}" &&
        posted["metadata"] == { "credit_item_id" => @credit_item.id.to_s }
    end
  end

  test "running again sends the same update" do
    stub_payment_intent_update

    2.times { LinkStripePaymentJob.perform_now(@order) }

    bodies = []
    assert_requested(:post, "#{STRIPE_PAYMENT_INTENTS_URL}/pi_test_link_order", times: 2) { |request| bodies << request.body }
    assert_equal 1, bodies.uniq.size
  end

  test "a request Stripe rejects is reported, not raised or retried" do
    stub_stripe_request_rejected(url: "#{STRIPE_PAYMENT_INTENTS_URL}/pi_test_link_order")

    assert_error_reported(Stripe::InvalidRequestError) do
      assert_no_enqueued_jobs do
        LinkStripePaymentJob.perform_now(@order)
      end
    end
  end

  test "Stripe being unavailable is retried, then reported" do
    # one request per job attempt, not the stripe gem's own retries too
    previous_retries = Stripe.max_network_retries
    Stripe.max_network_retries = 0
    stub_request(:post, "#{STRIPE_PAYMENT_INTENTS_URL}/pi_test_link_order").to_return(
      status: 500, headers: JSON_HEADERS, body: { error: { type: "api_error", message: "Stripe is down" } }.to_json
    )

    assert_no_error_reported do
      assert_enqueued_with(job: LinkStripePaymentJob, args: [ @order ]) do
        LinkStripePaymentJob.perform_now(@order)
      end
    end

    # the remaining attempts, each enqueued by the one before
    assert_error_reported(Stripe::APIError) do
      4.times { perform_enqueued_jobs }
    end
    assert_no_enqueued_jobs
    assert_requested :post, "#{STRIPE_PAYMENT_INTENTS_URL}/pi_test_link_order", times: 5
  ensure
    Stripe.max_network_retries = previous_retries
  end
end
