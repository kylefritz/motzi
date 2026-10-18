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
