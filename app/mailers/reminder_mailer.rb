class ReminderMailer < ApplicationMailer
  track extra: -> { {menu: params[:menu], pickup_day: params[:pickup_day]} }
  track open: true, click: true

  def day_of_email
    @menu = params[:menu]
    @user = params[:user]
    @menus = params[:menus] || []
    @order_items_by_menu = params[:order_items_by_menu] || []
    @pickup_day = params[:pickup_day]

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Pick up #{Setting.shop.name} today!",
         template_name: 'day_of_email')
  end

  def havent_ordered_email
    @menu = params[:menu]
    @user = params[:user]
    @menus = params[:menus] || []

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Make your selection soon! #{Setting.shop.name} - #{@menu.name}")
  end
end
