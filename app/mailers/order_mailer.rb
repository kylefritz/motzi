class OrderMailer < ApplicationMailer
  track extra: -> { {menu_id: params[:order].menu_id} }
  track open: true, click: true

  def confirmation_email
    @order = params[:order]
    @user = @order.user
    @menu = @order.menu

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Order Confirmation - #{Setting.shop.name} - #{@menu.name}")
  end
end
