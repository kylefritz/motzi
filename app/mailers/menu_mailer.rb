class MenuMailer < ApplicationMailer
  track extra: -> { {menu_id: params[:menu].id} }
  track open: true, click: true

  def weekly_menu_email
    @menu = params[:menu]
    @user = params[:user]

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "#{Setting.shop.name} - #{@menu.name}")
  end
end
