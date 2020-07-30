class ReminderMailer < ApplicationMailer
  track extra: -> { {menu_id: params[:menu].id} }
  track open: true, click: true

  def day_of_email_day1
    day_of_email
  end

  def day_of_email_day2
    day_of_email
  end

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
