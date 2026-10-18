class ConfirmationMailer < ApplicationMailer
  # Defense-in-depth against rapid-fire duplicate confirmations (#331): the
  # controller's advisory lock prevents duplicate orders, but the mailer was
  # observed double-invoked 121ms apart for the same order.
  ORDER_EMAIL_DEDUP_WINDOW = 10.seconds

  track extra: -> { { menu_id: params[:order].menu_id, order_id: params[:order].id } if params[:order].present? }
  track open: true, click: true

  around_action :log_render_duration
  around_deliver :log_delivery_duration

  def order_email
    @order = params[:order]
    @user = @order.user
    @menu = @order.menu

    claimed, prior_claim = claim_order_email(@order)
    unless claimed
      logger.warn "[ConfirmationMailer] suppressed duplicate order_email reason=same_content_within_window " \
        "order_id=#{@order.id} user_id=#{@user.id} menu_id=#{@menu.id} prior_claim_at=#{prior_claim} " \
        "window=#{ORDER_EMAIL_DEDUP_WINDOW.to_i}s"
      return
    end

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Order Confirmation - #{Setting.shop.name} - #{@menu.name}") do |format|
      format.text
      format.mjml
    end
  end

  def credit_email
    @credit_item = params[:credit_item]
    @user = @credit_item.user

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Credit Purchase Confirmation - #{Setting.shop.name}") do |format|
      format.text
      format.mjml
    end
  end

  # Keyed on the order's contents, not just its id, so a legitimate edit-and-
  # resend within the window still goes out while a double-invocation for the
  # same state is dropped. Public so the mailer preview can clear it.
  def self.order_email_dedup_key(order)
    items = order.order_items.order(:item_id, :pickup_day_id).pluck(:item_id, :quantity, :pickup_day_id)
    fingerprint = Digest::SHA256.hexdigest([ items, order.comments ].to_json)
    "confirmation_mailer/order_email/#{order.id}/#{fingerprint}"
  end

  private

  # Returns [claimed, prior_claim_at]. The window runs from the claim, which
  # happens before rendering. Solid Cache's write(unless_exist:) is not atomic
  # for a key that doesn't exist yet (its SELECT ... FOR UPDATE has no row to
  # lock), so two jobs running at once could both claim it; the advisory lock
  # makes the second wait until the first claim commits.
  def claim_order_email(order)
    key = self.class.order_email_dedup_key(order)
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql_array([ "SELECT pg_advisory_xact_lock(hashtext(?))", key ])
      )
      if Rails.cache.write(key, Time.current.iso8601(3), unless_exist: true, expires_in: ORDER_EMAIL_DEDUP_WINDOW)
        [ true, nil ]
      else
        [ false, Rails.cache.read(key) ]
      end
    end
  end

  def log_render_duration
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    return unless message_rendered?

    logger.info "[ConfirmationMailer] rendered #{action_name} #{log_ids} render_ms=#{elapsed_ms(started)}"
  end

  def log_delivery_duration
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    return unless message_rendered?

    logger.info "[ConfirmationMailer] delivered #{action_name} #{log_ids} deliver_ms=#{elapsed_ms(started)}"
  end

  # A suppressed order_email returns before calling mail, leaving an empty
  # message that never goes out.
  def message_rendered?
    message.to.present?
  end

  def log_ids
    ids = { order_id: @order&.id, credit_item_id: @credit_item&.id, user_id: @user&.id }.compact
    ids.map { |k, v| "#{k}=#{v}" }.join(" ")
  end

  def elapsed_ms(started)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(1)
  end
end
