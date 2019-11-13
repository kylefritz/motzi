class MenuMailerPreview < ActionMailer::Preview
  def weekly_menu_email
    menu = Menu.current
    user = User.last
    MenuMailer.with(menu: menu, user: user).weekly_menu_email
  end
end
