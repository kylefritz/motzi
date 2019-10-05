class WeeklyMailer < ApplicationMailer
  default bcc: -> { %("#{User.pluck(:name)}" <#{User.pluck(:email)}> ) }

  def weekly_mail
    @menu = params[:menu]
    mail(subject: "Motzi Bread - #{@menu.name}")
  end
end
