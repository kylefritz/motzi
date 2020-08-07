class ConfirmationMailer < ApplicationMailer
  track extra: -> { {menu_id: params[:order].menu_id} if params[:order].present? }
  track open: true, click: true

  def order_email
    @order = params[:order]
    @user = @order.user
    @menu = @order.menu

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Order Confirmation - #{Setting.shop.name} - #{@menu.name}")
  end

  def credit_email
    @credit_item = params[:credit_item]
    @user = @credit_item.user

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Credit Purchase Confirmation - #{Setting.shop.name}")
  end
end
