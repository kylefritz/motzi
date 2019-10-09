class MenuMailer < ApplicationMailer
  def weekly_menu
    @menu = params[:menu]
    @user = params[:user]
    mail(to: "#{@user.name} <#{@user.email}>", cc: @user.additional_email, subject: "Motzi Bread - #{@menu.name}")
  end
end
