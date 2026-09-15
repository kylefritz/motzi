class OrdersController < ApplicationController
  class OrderError < StandardError;end

  include UserHashidable
  include RenderCurrentOrder

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

    user = User.create!(params.permit(:first_name, :last_name, :email, :phone, :mailing_list))
    if user.mailing_list?
      _, message = MailerliteSubscriber.subscribe(user)
      ActiveAdmin::Comment.create!(body: message, namespace: "admin", resource: user, author: User.system)
    end
    user
  end

  def create
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
      user = current_user_or_create_user
      order_params = params.permit(:comments).merge(menu: @menu, user: user)

      order = Order.create!(order_params)
      if params.fetch(:cart).empty?
        raise OrderError.new("Add an item to your cart")
      end
      cart_items.each { |attrs| order.order_items.create!(attrs) }

      # figure out if we need to charge this person or if we're using credits
      if params[:price].present?

        # we let the customer set the price so ok to trust customer input
        price = params[:price].to_f.clamp(0, 250)
        price_cents = (price * 100).to_i

        # make stripe change
        if price > 0
          if params[:token].blank?
            raise OrderError.new("Stripe credit card not submitted")
          end
          charge = Stripe::Charge.create({
            amount: price_cents,
            currency: "usd",
            source: params[:token],
            metadata: {
              user_id: user.id,
              order_id: order.id
            },
            description: "Order ##{order.id} - #{order.item_list}",
            receipt_email: user.email
          })
        end
        order.update!(
          stripe_charge_id: charge.try(:id),
          stripe_receipt_url: charge.try(:receipt_url),
          stripe_charge_amount: price,
        )
      end

      ahoy.track "order_created"
      [ user, order ]
    end

    # send confirmation email
    ConfirmationMailer.with(order: @order).order_email.deliver_later

    # Place order in the correct response slot (regular vs holiday)
    if @menu.holiday?
      @holiday_order = @order
      @order = nil
    end
    render_current_order(nil, @user)

    rescue OrderError => e
      render_validation_failed(e.message)
    rescue Stripe::CardError => e
      # https://stripe.com/docs/api/errors/handling
      logger.warn "Stripe::CardError Status=#{e.http_status} Type=#{e.error.type} Charge ID=#{e.error.charge} \
        Code=#{e.error.code} decline_code=#{e.error.decline_code} param=#{e.error.param} message=#{e.error.message}"

      render_validation_failed(e.error.message)
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
      order.update!(params.permit(:comments))
      order.order_items.destroy_all
      cart_items.each { |attrs| order.order_items.create!(attrs) }

      # send confirmation email
      ConfirmationMailer.with(order: order).order_email.deliver_later

      ahoy.track "order_updated"
    end

    # Place order in the correct response slot (regular vs holiday)
    if order.menu.holiday?
      @holiday_order = order
    else
      @order = order
    end
    render_current_order

    rescue OrderError => e
      render_validation_failed(e.message)
  end

  private

  # A real paid marketplace order results in a Stripe charge (price > 0 with a
  # card token), which sets stripe_charge_id and so is excluded from credit
  # accounting. A $0 or token-less order would leave stripe_charge_id NULL and
  # count against the member's credit balance.
  def paid_marketplace_order?
    params[:price].to_f > 0 && params[:token].present?
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

  def render_ordering_closed
    render_validation_failed("ordering for this menu is closed")
  end

  def render_validation_failed(message)
    render json: { message: message }, status: :unprocessable_content
  end
end
