class Previews::MenuMailerPreview < ActionMailer::Preview
  def weekly_menu
    MenuMailer.with(menu: @menu, user: @user).menu_email
  end
end
