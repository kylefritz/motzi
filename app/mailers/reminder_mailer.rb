class ReminderMailer < ApplicationMailer
  track extra: -> { {menu_id: params[:menu].id} }
  track open: true, click: true

  def day_of_email
    @menu = params[:menu]
    @user = params[:user]
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    @bakers_note_html = renderer.render(@menu.bakers_note).html_safe

    mail(to: %("#{@user.name}" <#{@user.email}>),
         cc: @user.additional_email,
         subject: "Motzi Bread pick up today!")
  end
end
