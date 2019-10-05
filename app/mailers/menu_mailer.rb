class MenuMailer < ApplicationMailer
  default bcc: -> { %("#{User.pluck(:name)}" <#{User.pluck(:email)}> ) }

  def menu_mail
    @menu = params[:menu]
    mail(subject: "Motzi Bread - #{@menu.name}")
  end
end
