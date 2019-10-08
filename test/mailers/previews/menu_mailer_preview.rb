class MenuMailerPreview < ActionMailer::Preview
  def weekly_menu
    menu = Menu.current
    user = User.last
    MenuMailer.with(menu: menu, user: user).weekly_menu
  end
end
