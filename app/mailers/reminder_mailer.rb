class ReminderMailer < ApplicationMailer
  track extra: -> { {menu: params[:menu], pickup_day: params[:pickup_day]} }
  track open: true, click: true

  def day_of_email
    @menu = params[:menu]
    @user = params[:user]
    @order_items = params[:order_items]

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Pick up #{Setting.shop.name} today!",
         template_name: 'day_of_email')
  end

  def havent_ordered_email
    @menu = params[:menu]
    @user = params[:user]

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Make your selection soon! #{Setting.shop.name} - #{@menu.name}")
  end
end
