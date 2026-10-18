# Records what a PaymentIntent paid for. The controllers use it once a payment
# succeeds in the browser, and the payment_intent.succeeded webhook uses it to
# record payments the browser never came back for (#412).
#
# Recording the same intent twice is a no-op: the unique index on
# stripe_payment_intent_id lets only one of the browser and the webhook write
# it, and the other gets the existing record back.
class StripeCheckout
  module Fulfillment
    module_function

    # Records the purchase an intent's metadata describes, unless it already
    # was. Returns the Order or CreditItem, or nil for an intent we didn't make.
    def record!(intent)
      metadata = intent.metadata.to_h.transform_keys(&:to_s)
      case metadata["kind"]
      when "order" then record_order!(intent, metadata)
      when "credits" then record_credits!(intent, metadata)
      end
    end

    # Creates the order and its items, then emails the confirmation. payment
    # is nil for a member spending credits.
    def create_order!(menu:, user:, comments:, cart_items:, payment:, source: "order_create")
      order = Order.new(menu:, user:, comments:)
      cart_items.each { |attrs| order.order_items.build(attrs) }
      order.assign_attributes(payment.record_attrs) if payment
      order.save!
      deliver_after_commit(ConfirmationMailer.with(order:).order_email,
                           "order_email source=#{source} order_id=#{order.id} user_id=#{order.user_id}")
      order
    end

    # Adds the credits, turns on the weekly menu, then emails the receipt.
    def add_credits!(user:, quantity:, description:, payment:, breads_per_week:, source: "credit_purchase")
      credit_item = user.credit_items.create!(
        **payment.record_attrs,
        memo: "#{description}. Paid via Stripe $#{payment.amount.to_s('F')}.",
        quantity: quantity,
        good_for_weeks: 42
      )
      user.update(breads_per_week: breads_per_week.to_f, receive_weekly_menu: true)
      deliver_after_commit(ConfirmationMailer.with(credit_item:).credit_email,
                           "credit_email source=#{source} credit_item_id=#{credit_item.id} user_id=#{user.id}")
      credit_item
    end

    # Mail only once the record is committed. Solid Queue shares the app's
    # database, so a job enqueued in a transaction that rolls back (say the
    # webhook recorded this payment first) is rolled back with it, but that
    # stops holding if the queue ever moves to its own database. The
    # "enqueued" log line (#423) is written only when the job really is.
    def deliver_after_commit(mail, log_details)
      ActiveRecord.after_all_transactions_commit do
        mail.deliver_later
        Rails.logger.info "[ConfirmationMailer] enqueued #{log_details}"
      end
    end

    def credits_description(quantity)
      bundle = CreditBundle.find_by(credits: quantity)
      [ "#{quantity}x credits", bundle.try(:name_description) ].compact.join(" - ")
    end

    def record_order!(intent, metadata)
      existing_or_create(Order, intent) do |payment|
        menu = Menu.find(StripeCheckout.read_metadata(metadata, "purchase_menu_id"))
        cart_items = StripeCheckout.decode_cart(StripeCheckout.read_metadata(metadata, "purchase_cart"))
        Order.transaction do
          user = User.find_by(id: metadata["user_id"]) || User.find_by(email: metadata["email"]) ||
                 User.create_guest!(
                   email: metadata["email"],
                   first_name: metadata["first_name"],
                   last_name: metadata["last_name"],
                   phone: metadata["phone"],
                   mailing_list: metadata["mailing_list"] == "true"
                 )
          create_order!(menu:, user:, comments: StripeCheckout.read_metadata(metadata, "comments").presence,
                        cart_items:, payment:, source: "stripe_webhook")
        end
      end
    end

    def record_credits!(intent, metadata)
      existing_or_create(CreditItem, intent) do |payment|
        quantity = metadata["purchase_credits"].to_i
        add_credits!(user: User.find(metadata["purchase_user_id"]), quantity:,
                     description: credits_description(quantity), payment:,
                     breads_per_week: metadata["breads_per_week"], source: "stripe_webhook")
      end
    end

    def existing_or_create(model, intent)
      existing = model.find_by(stripe_payment_intent_id: intent.id)
      return existing if existing

      payment = StripeCheckout::Payment.from_intent(intent)
      begin
        yield payment
      rescue ActiveRecord::RecordNotUnique
        # The browser recorded it (or created the guest) while we were working.
        model.find_by(stripe_payment_intent_id: intent.id) || raise
      end
    end
  end
end
