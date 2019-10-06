class MenuMailer < ApplicationMailer
  # TODO: sending all users
  default bcc: -> { User.all.pluck(:email) }

  def menu_email
    @menu = params[:menu]
    mail(subject: "Motzi Bread - #{@menu.name}")
  end
end
