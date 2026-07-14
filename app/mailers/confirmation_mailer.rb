class ConfirmationMailer < ApplicationMailer
  # Defense-in-depth against rapid-fire duplicate confirmations (#331): the
  # controller's advisory lock prevents duplicate orders, but the mailer was
  # observed double-invoked 121ms apart for the same order.
  ORDER_EMAIL_DEDUP_WINDOW = 10.seconds

  track extra: -> { { menu_id: params[:order].menu_id, order_id: params[:order].id } if params[:order].present? }
  track open: true, click: true

  def order_email
    @order = params[:order]
    @user = @order.user
    @menu = @order.menu

    if duplicate_order_email?(@order)
      logger.warn "suppressed duplicate ConfirmationMailer#order_email order_id=#{@order.id} user_id=#{@user.id} menu_id=#{@menu.id}"
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

  private

  # Keyed on the order's contents, not just its id, so a legitimate edit-and-
  # resend within the window still goes out while a double-invocation for the
  # same state is dropped. unless_exist makes check-and-claim a single write.
  def duplicate_order_email?(order)
    items = order.order_items.order(:item_id, :pickup_day_id).pluck(:item_id, :quantity, :pickup_day_id)
    fingerprint = Digest::SHA256.hexdigest([items, order.comments].to_json)
    key = "confirmation_mailer/order_email/#{order.id}/#{fingerprint}"

    !Rails.cache.write(key, true, unless_exist: true, expires_in: ORDER_EMAIL_DEDUP_WINDOW)
  end
end
