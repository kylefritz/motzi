class WelcomeController < ApplicationController
  def show
    redirect_to '/menu'
  end
end
