require "test_helper"

class StripeCheckout::FulfillmentTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @payment = StripeCheckout::Payment.new(payment_intent_id: "pi_test_mail", charge_id: "ch_test_mail",
                                           receipt_url: nil, amount: BigDecimal("5"))
    @cart_items = [ { item_id: items(:classic).id, pickup_day_id: pickup_days(:w2_d1_thurs).id, quantity: 1 } ]
  end

  def create_order!
    StripeCheckout::Fulfillment.create_order!(menu: menus(:week2), user: users(:kyle), comments: nil,
                                              cart_items: @cart_items, payment: @payment)
  end

  test "the confirmation email is sent once the order commits" do
    assert_enqueued_emails 1 do
      Order.transaction { create_order! }
    end
  end

  # e.g. the browser's request losing the race to the webhook: its order never
  # commits, so it must not email the customer a second time
  test "no confirmation email for an order whose transaction rolls back" do
    assert_no_enqueued_emails do
      Order.transaction do
        create_order!
        raise ActiveRecord::Rollback
      end
    end
    assert_nil Order.find_by(stripe_payment_intent_id: "pi_test_mail")
  end

  test "the [ConfirmationMailer] enqueued log line is written only for a committed order" do
    logged = capture_log do
      Order.transaction do
        create_order!
        raise ActiveRecord::Rollback
      end
    end
    assert_no_match(/\[ConfirmationMailer\] enqueued/, logged)

    logged = capture_log { Order.transaction { create_order! } }
    assert_match(/\[ConfirmationMailer\] enqueued order_email source=order_create order_id=\d+ user_id=#{users(:kyle).id}/, logged)
  end

  test "no credits email when the credit purchase rolls back" do
    assert_no_enqueued_emails do
      CreditItem.transaction do
        StripeCheckout::Fulfillment.add_credits!(user: users(:ljf), quantity: 6, description: "6x credits",
                                                 payment: @payment, breads_per_week: 1)
        raise ActiveRecord::Rollback
      end
    end
  end

  test "the payment intent is linked to the order once it commits" do
    assert_enqueued_jobs 0, only: LinkStripePaymentJob do
      Order.transaction do
        create_order!
        raise ActiveRecord::Rollback
      end
    end

    order = nil
    assert_enqueued_jobs 1, only: LinkStripePaymentJob do
      Order.transaction { order = create_order! }
    end
    assert_enqueued_with job: LinkStripePaymentJob, args: [ order ]
  end

  test "the payment intent is linked to the credit item once it commits" do
    # a fresh user each time: the rolled back credit item stays in a loaded
    # user's credit_items and would be saved along with them
    add_credits = lambda do
      StripeCheckout::Fulfillment.add_credits!(user: User.find(users(:ljf).id), quantity: 6, description: "6x credits",
                                               payment: @payment, breads_per_week: 1)
    end
    assert_enqueued_jobs 0, only: LinkStripePaymentJob do
      CreditItem.transaction do
        add_credits.call
        raise ActiveRecord::Rollback
      end
    end

    credit_item = nil
    assert_enqueued_jobs 1, only: LinkStripePaymentJob do
      credit_item = add_credits.call
    end
    assert_enqueued_with job: LinkStripePaymentJob, args: [ credit_item ]
  end

  test "nothing to link for an order without a payment intent" do
    assert_enqueued_jobs 0, only: LinkStripePaymentJob do
      StripeCheckout::Fulfillment.create_order!(menu: menus(:week2), user: users(:kyle), comments: nil,
                                                cart_items: @cart_items, payment: StripeCheckout::Payment.free)
    end
    assert_enqueued_jobs 0, only: LinkStripePaymentJob do
      StripeCheckout::Fulfillment.create_order!(menu: menus(:week2), user: users(:ljf), comments: nil,
                                                cart_items: @cart_items, payment: nil)
    end
  end

  test "recording an intent again doesn't link it again" do
    intent = Stripe::PaymentIntent.construct_from(
      id: "pi_test_relink", object: "payment_intent", status: "succeeded", amount: 500,
      latest_charge: { id: "ch_test_relink", object: "charge", amount: 500 },
      metadata: { kind: "order", email: users(:kyle).email, user_id: users(:kyle).id.to_s,
                  purchase_menu_id: menus(:week2).id.to_s,
                  purchase_cart: StripeCheckout.encode_cart(@cart_items) }
    )
    assert_enqueued_jobs 1, only: LinkStripePaymentJob do
      2.times { StripeCheckout::Fulfillment.record!(intent) }
    end
  end

  private

  def capture_log
    io = StringIO.new
    original = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    yield
    io.string
  ensure
    Rails.logger = original
  end
end
