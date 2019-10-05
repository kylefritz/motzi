class MenuController < ApplicationController
  def send
    @menu = Menu.find(params[:menu])
    WeeklyMailer.with(menu: @menu).weekly_mail.deliver_now
  end
end
