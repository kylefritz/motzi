class MenuMailer < ApplicationMailer
  def weekly_menu
    @menu = params[:menu]
    @user = params[:user]
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    @bakers_note_html = renderer.render(@menu.bakers_note).html_safe

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Motzi Bread - #{@menu.name}")
  end
end
