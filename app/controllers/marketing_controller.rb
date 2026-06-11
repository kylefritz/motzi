class MarketingController < ApplicationController
  layout "marketing"
  skip_before_action :authenticate_user!
  skip_before_action :push_gon
end
