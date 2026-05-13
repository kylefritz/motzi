class MarketingController < ApplicationController
  layout "marketing"
  skip_before_action :authenticate_user!
end
