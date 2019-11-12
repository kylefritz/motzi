class ReminderMailer < ApplicationMailer
  track extra: -> { {menu_id: params[:menu].id} }
  track open: true, click: true

  def day_of_email
    @menu = params[:menu]
    @user = params[:user]

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Motzi Bread pick up today!")
  end

  def havent_ordered_email
    @menu = params[:menu]
    @user = params[:user]

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Make your selection soon! Motzi Bread - #{@menu.name}")
  end
end
