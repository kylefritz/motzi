class MenuController < ApplicationController
  def show
    render json: Menu.current
  end
end
