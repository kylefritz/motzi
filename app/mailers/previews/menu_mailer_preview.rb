
class MenuMailerPreview < ActionMailer::Preview
  def menu_email
    MenuMailer.with(menu: @menu).menu_email
  end
end
