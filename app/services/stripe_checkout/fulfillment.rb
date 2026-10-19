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

    # Records the purchase a paid intent's metadata describes, unless it
    # already was. Returns the Order or CreditItem, or nil for an intent we
    # didn't make or one that has been refunded.
    def record!(intent, source: "stripe_webhook")
      metadata = intent.metadata.to_h.transform_keys(&:to_s)
      model = MODELS[metadata["kind"]]
      return unless model

      existing = model.find_by(stripe_payment_intent_id: intent.id)
      return existing if existing

      if StripeCheckout.refunded?(intent)
        Rails.logger.warn "StripeCheckout: not recording refunded payment intent #{intent.id}"
        return
      end

      payment = StripeCheckout::Payment.from_intent(intent)
      begin
        model == Order ? record_order!(payment, metadata, source) : record_credits!(payment, metadata, source)
      rescue ActiveRecord::RecordNotUnique
        # The other path (browser or webhook) recorded it while we were working.
        model.find_by(stripe_payment_intent_id: intent.id) || raise
      end
    end

    MODELS = { "order" => Order, "credits" => CreditItem }.freeze

    # Whether the browser or the webhook already recorded this intent.
    def recorded?(payment_intent_id)
      MODELS.values.any? { |model| model.exists?(stripe_payment_intent_id: payment_intent_id) }
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
      link_payment_after_commit(order)
      order
    end

    # Adds the credits, turns on the weekly menu, then emails the receipt.
    def add_credits!(user:, quantity:, description:, payment:, breads_per_week:, source: "credit_purchase")
      credit_item = user.credit_items.create!(
        **payment.record_attrs,
        memo: "#{description}. Paid via Stripe $#{payment.amount.to_s('F')}.",
        quantity: quantity
      )
      user.update(breads_per_week: breads_per_week.to_f, receive_weekly_menu: true)
      deliver_after_commit(ConfirmationMailer.with(credit_item:).credit_email,
                           "credit_email source=#{source} credit_item_id=#{credit_item.id} user_id=#{user.id}")
      link_payment_after_commit(credit_item)
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

    # Names the record on its PaymentIntent (#427), once it's committed for
    # the same reason as deliver_after_commit. Only the browser or the webhook
    # gets here for a given intent; the other finds the existing record.
    def link_payment_after_commit(record)
      return if record.stripe_payment_intent_id.blank?

      ActiveRecord.after_all_transactions_commit { LinkStripePaymentJob.perform_later(record) }
    end

    def credits_description(quantity)
      bundle = CreditBundle.find_by(credits: quantity)
      [ "#{quantity}x credits", bundle.try(:name_description) ].compact.join(" - ")
    end

    def record_order!(payment, metadata, source)
      menu = Menu.find(StripeCheckout.read_metadata(metadata, "purchase_menu_id"))
      cart_items = StripeCheckout.decode_cart(StripeCheckout.read_metadata(metadata, "purchase_cart"))
      Order.transaction do
        user = User.find_by(id: metadata["user_id"].presence) || find_or_create_guest!(metadata)
        create_order!(menu:, user:, comments: StripeCheckout.read_metadata(metadata, "comments").presence,
                      cart_items:, payment:, source:)
      end
    end

    def record_credits!(payment, metadata, source)
      quantity = metadata["purchase_credits"].to_i
      add_credits!(user: User.find(metadata["purchase_user_id"]), quantity:,
                   description: credits_description(quantity), payment:,
                   breads_per_week: metadata["breads_per_week"], source:)
    end

    # The guest the intent was paid for. The browser and the webhook can race
    # to create them, so losing that race (the unique email index, or
    # Devise's uniqueness validation if the other side committed first) means
    # they exist now. The savepoint keeps the surrounding transaction usable.
    def find_or_create_guest!(metadata)
      email = metadata["email"].to_s.strip.downcase
      User.find_by(email:) || User.transaction(requires_new: true) do
        User.create_guest!(email:, first_name: metadata["first_name"], last_name: metadata["last_name"],
                           phone: metadata["phone"], mailing_list: metadata["mailing_list"] == "true")
      end
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      User.find_by(email:) || raise
    end
  end
end
