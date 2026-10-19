class OrdersController < ApplicationController
  class OrderError < StandardError;end

  include UserHashidable
  include RenderCurrentOrder
  include StripeCheckoutResponses

  def current_user_or_create_user
    if !params.include?(:email)
      require_hashid_user_or_devise_user!
      return current_user
    end

    if (existing_user = User.find_by(email: params.fetch(:email).strip.downcase)).present?
      # Guest checkout may only attach to an existing account for a genuinely
      # paid marketplace order. Without this, an unauthenticated request could
      # place a credit-spending order in any member's name just by knowing their
      # email — draining their credits. A returning member must sign in.
      unless paid_marketplace_order?
        raise OrderError.new("Email passed as param — Please use a link from a menu email or sign in to place your order")
      end
      return existing_user
    end

    User.create_guest!(params.permit(:first_name, :last_name, :email, :phone, :mailing_list))
  end

  def create
    # Finishing a card payment after 3D Secure: the money has moved, so the
    # order is recorded from the payment, without re-running checkout.
    return record_paid_order if params[:payment_intent_id].present?

    target_menu = params[:menu_id].present? ? Menu.find(params[:menu_id]) : Menu.current

    unless current_admin_user.present? || target_menu.id.in?([ Menu.current.id, Menu.current_holiday&.id ].compact)
      return render_validation_failed("this menu is not available for ordering")
    end

    @menu = target_menu

    if @menu.ordering_closed? && current_admin_user.blank?
      return render_ordering_closed
    end

    # validated up front so a bad cart never creates an order
    cart_items = order_item_attrs_for_cart(@menu, params.fetch(:cart))
    pricing = OrderPricing.new(menu: @menu, cart_items: cart_items)
    enforce_minimum_price!(pricing)

    @user, @order = Order.transaction do
      # Advisory lock prevents race condition where two simultaneous requests
      # both pass the duplicate check before either commits.
      lock_key = Order.creation_lock_key(user_id: current_user&.id, menu_id: @menu.id)
      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql_array([ "SELECT pg_advisory_xact_lock(?)", lock_key ])
      )

      if current_user&.order_for_menu(@menu).present?
        logger.warn "user=#{current_user.email} already placed an order for menu #{@menu.id}. returning current order"
        return render_current_order
      end
      if params.fetch(:cart).empty?
        raise OrderError.new("Add an item to your cart")
      end
      enforce_item_limits!(@menu, cart_items)
      user = current_user_or_create_user

      # figure out if we need to charge this person or if we're using credits
      if params[:price].present?
        # pay what you can: the customer sets the price, which
        # enforce_minimum_price! has already checked covers fixed-price items
        price_cents = StripeCheckout.to_cents(price_param.clamp(0, pricing.maximum))
        payment = price_cents.positive? ? charge_for_order!(user, cart_items, price_cents) : StripeCheckout::Payment.free
      end

      order = StripeCheckout::Fulfillment.create_order!(
        menu: @menu, user: user, comments: params[:comments], cart_items: cart_items, payment: payment
      )
      ahoy.track "order_created"
      [ user, order ]
    end

    render_order(@order, @user)

    rescue OrderError => e
      render_validation_failed(e.message)
    rescue ActiveRecord::RecordNotUnique => e
      # the payment_intent.succeeded webhook recorded this payment first
      existing = @payment_intent_id && Order.find_by(stripe_payment_intent_id: @payment_intent_id)
      raise e unless existing
      render_order(existing, existing.user)
  end

  def update
    order = Order.find(params[:id])

    if current_admin_user.blank?
      if order.user_id != current_user.id
        return render json: { message: "not your order" }, status: :unauthorized
      end

      if order.menu.ordering_closed?
        return render_ordering_closed
      end
    end

    cart_items = order_item_attrs_for_cart(
      order.menu, params[:cart],
      existing: order.order_items.pluck(:item_id, :pickup_day_id).to_set
    )

    Order.transaction do
      enforce_item_limits!(order.menu, cart_items, order: order)
      order.update!(params.permit(:comments))
      order.order_items.destroy_all
      cart_items.each { |attrs| order.order_items.create!(attrs) }

      # send confirmation email
      ConfirmationMailer.with(order: order).order_email.deliver_later
      logger.info "[ConfirmationMailer] enqueued order_email source=order_update order_id=#{order.id} user_id=#{order.user_id}"

      ahoy.track "order_updated"
    end

    render_order(order, current_user)

    rescue OrderError => e
      render_validation_failed(e.message)
  end

  private

  # A real paid marketplace order results in a Stripe charge (price > 0 with a
  # card payment), which sets stripe_charge_id and so is excluded from credit
  # accounting. A $0 or card-less order would leave stripe_charge_id NULL and
  # count against the member's credit balance.
  def paid_marketplace_order?
    price_param.positive? && params[:confirmation_token_id].present?
  end

  # The 3D Secure leg: record the order the verified payment paid for. The
  # payment must be for the email checking out (or the signed-in member).
  def record_paid_order
    requester_email = (params[:email].presence || current_user&.email).to_s.strip.downcase
    intent = StripeCheckout.paid_intent!(params[:payment_intent_id], kind: "order") do |metadata|
      requester_email.present? && metadata["email"] == requester_email
    end
    order = StripeCheckout::Fulfillment.record!(intent, source: "order_create")
    raise StripeCheckout::PaymentError, StripeCheckout::REJECTED_MESSAGE unless order

    ahoy.track "order_created" if order.previously_new_record?
    render_order(order, order.user)
  end

  # Charges the card for a marketplace or holiday order (or verifies the
  # payment the browser just authenticated). Everything the
  # payment_intent.succeeded webhook needs to place the order goes in the
  # metadata, in case the browser never comes back.
  def charge_for_order!(user, cart_items, price_cents)
    item_list = Order.new(menu: @menu).tap { |o| cart_items.each { |attrs| o.order_items.build(attrs) } }.item_list
    checkout = StripeCheckout.new(
      kind: "order",
      amount_cents: price_cents,
      email: user.email,
      description: "#{@menu.name} - #{item_list}",
      purchase: { menu_id: @menu.id, cart: StripeCheckout.encode_cart(cart_items) },
      metadata: {
        # a guest created by this request rolls back if 3D Secure is needed,
        # so only an existing account is recorded by id
        user_id: (user.id unless user.previously_new_record?),
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone,
        mailing_list: user.mailing_list?,
        # capped so the metadata stays within Stripe's key limit; the order
        # itself keeps the full comment
        comments: params[:comments].to_s.truncate(COMMENTS_METADATA_LIMIT).presence
      }
    )
    checkout.charge!(params[:confirmation_token_id]).tap do |payment|
      @payment_intent_id = payment.payment_intent_id
    end
  end

  COMMENTS_METADATA_LIMIT = 1_500

  # Place order in the correct response slot (regular vs holiday). The
  # account (its hashid signs you in, and its credit balance) is only shown
  # to its owner: the signed-in member, or a guest this request created. A
  # guest paying with an existing member's email just gets their order.
  def render_order(order, user)
    if order.menu.holiday?
      @holiday_order = order
      @order = nil
    else
      @order = order
    end
    @user = (user if user == current_user || user&.previously_new_record?)
    render_current_order(nil, @user)
  end

  # A card-paid order must cover its fixed-price items (#412). A guest
  # checking out by email always pays by card, so leaving the price off
  # counts as $0 rather than skipping the check.
  def enforce_minimum_price!(pricing)
    return unless params[:price].present? || params.include?(:email)

    if pricing.below_minimum?(price_param)
      raise OrderError.new(pricing.minimum_message)
    end
  end

  # Turns the submitted cart into order item attributes, rejecting any line the
  # menu doesn't offer (#341). The item must be on the menu and offered on the
  # chosen pickup day (menu_item_pickup_days), which must belong to this menu.
  # Pay it forward isn't a menu item, so it only needs one of the menu's days.
  #
  # `existing` holds [item_id, pickup_day_id] pairs already on the order being
  # edited. They're let through so a bakery trimming the menu after people have
  # ordered doesn't lock those members out of editing their order.
  def order_item_attrs_for_cart(menu, cart, existing: Set.new)
    pickup_days = menu.pickup_days.to_a
    pickup_day_ids = pickup_days.map(&:id).to_set
    menu_item_ids = menu.menu_items.pluck(:item_id).to_set
    offered = MenuItemPickupDay.joins(:menu_item)
                               .where(menu_items: { menu_id: menu.id })
                               .pluck("menu_items.item_id", :pickup_day_id)
                               .to_set

    cart.map do |cart_item_params|
      item_id = cart_item_params[:item_id].to_i
      pickup_day_id = (cart_item_params[:pickup_day_id] || pickup_days.first&.id).to_i

      unless existing.include?([ item_id, pickup_day_id ])
        # only looked up when a line is rejected, so valid carts skip the query
        item_name = -> { Item.find_by(id: item_id)&.name || "An item in your cart" }
        if item_id != Item::PAY_IT_FORWARD_ID && !menu_item_ids.include?(item_id)
          raise OrderError.new("#{item_name.call} isn't on this menu. Please remove it from your cart")
        elsif !pickup_day_ids.include?(pickup_day_id)
          raise OrderError.new("#{item_name.call} has a pickup day that isn't part of this menu")
        elsif item_id != Item::PAY_IT_FORWARD_ID && !offered.include?([ item_id, pickup_day_id ])
          day = pickup_days.find { |pd| pd.id == pickup_day_id }.day_str
          raise OrderError.new("#{item_name.call} isn't available for #{day} pickup. Please remove it from your cart")
        end
      end

      {
        item_id: item_id,
        quantity: cart_item_params[:quantity].presence || 1,
        pickup_day_id: pickup_day_id
      }
    end
  end

  # Rejects a cart that would push an item past its limit for a pickup day
  # (#410). The limited menu_item_pickup_days rows are locked (in id order, so
  # concurrent carts can't deadlock) before counting what's already ordered, so
  # two simultaneous orders can't both take the last one. nil is unlimited and
  # 0 is sold out; pay it forward isn't a menu item, so it has no limit.
  #
  # When editing, `order` isn't counted against the limit, and a line can keep
  # or lower the quantity it already had even if the item has since sold out
  # (limits are often dropped to 0 after people have ordered).
  def enforce_item_limits!(menu, cart_items, order: nil)
    requested = cart_items.reject { |attrs| attrs[:item_id] == Item::PAY_IT_FORWARD_ID }
                          .group_by { |attrs| [ attrs[:item_id], attrs[:pickup_day_id] ] }
                          .transform_values { |lines| lines.sum { |attrs| attrs[:quantity].to_i } }
    return if requested.empty?

    limits = MenuItemPickupDay.joins(:menu_item)
                              .where(menu_items: { menu_id: menu.id, item_id: requested.keys.map(&:first) },
                                     pickup_day_id: requested.keys.map(&:last))
                              .where.not(limit: nil)
                              .order(:id)
                              .lock("FOR UPDATE OF menu_item_pickup_days")
                              .pluck("menu_items.item_id", :pickup_day_id, :limit)
                              .to_h { |item_id, pickup_day_id, limit| [ [ item_id, pickup_day_id ], limit ] }
                              .slice(*requested.keys)
    return if limits.empty?

    ordered = menu.item_counts
    previous = order ? order.order_items.group(:item_id, :pickup_day_id).sum(:quantity) : {}

    limits.each do |(item_id, pickup_day_id), limit|
      quantity = requested[[ item_id, pickup_day_id ]]
      already_had = previous.fetch([ item_id, pickup_day_id ], 0)
      next if quantity <= already_had

      ordered_by_others = ordered.dig(item_id, pickup_day_id).to_i - already_had
      next if ordered_by_others + quantity <= limit

      left = [ limit - ordered_by_others, 0 ].max
      name = Item.find(item_id).name
      day = menu.pickup_days.find(pickup_day_id).day_str
      if left.zero?
        raise OrderError.new("#{name} is sold out for #{day}. Please remove it from your cart")
      end
      raise OrderError.new("Only #{left} #{name} left for #{day}. Please update your cart")
    end
  end

  def render_ordering_closed
    render_validation_failed("ordering for this menu is closed")
  end

  def render_validation_failed(message)
    render json: { message: message }, status: :unprocessable_content
  end
end
