class ApplicationController < ActionController::Base
  before_action :set_paper_trail_whodunnit

  before_action :authenticate_user!

  def user_for_paper_trail
    current_user
  end

  def authenticate_admin_user!
    # TODO: implement
    # used by active_admin
  end
  
  def current_admin_user
    if current_user&.is_admin?
      current_user
    end
  end
end
