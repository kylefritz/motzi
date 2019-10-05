class ApplicationController < ActionController::Base
  def authenticate_admin_user!
    # TODO: implement
  end
  
  def current_admin_user
    if Rails.env.development?
      Admin.first
    end
  end
end
