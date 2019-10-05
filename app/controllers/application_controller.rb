class ApplicationController < ActionController::Base
  before_action :set_paper_trail_whodunnit

  def user_for_paper_trail
    byebug
    current_admin_user ? current_admin_user.id : 'N/A'
  end

  def authenticate_admin_user!
    # TODO: implement
  end
  
  def current_admin_user
    if Rails.env.development?
      User.where(is_admin: true).first
    end
  end
end
