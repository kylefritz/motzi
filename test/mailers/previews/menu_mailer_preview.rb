class MenuMailerPreview < ApplicationMailerPreview
  def weekly_menu_email
    user = User.last
    return missing('No current users found.') unless user

    menu = Menu.current
    return missing('No current menu found.') unless menu

    MenuMailer.with(menu: menu, user: user).weekly_menu_email
  end
end
