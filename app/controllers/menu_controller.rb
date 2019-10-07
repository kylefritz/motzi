class MenuController < ApplicationController
  def show
    @menu = Menu.current
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @menu }
    end
  end
end
