class MenuController < ApplicationController
  def send
    @menu = Menu.find(params[:menu])
    MenuMailer.with(menu: @menu).menu_mail.deliver_now
  end
end
