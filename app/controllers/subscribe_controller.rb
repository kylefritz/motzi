class SubscribeController < ApplicationController
  layout "marketing"
  skip_before_action :authenticate_user!

  def show
  end
end
