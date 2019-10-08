class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  before_action :set_paper_trail_whodunnit
  before_action :authenticate_user!

  def user_for_paper_trail
    current_user&.id
  end

  def redirect_unless_user_is_admin!
    # used by active admin to keep out non-admins
    unless current_user&.is_admin?
      logger.info "its NOT ok"
      return redirect_to '/', alert: 'you must be an admin'
    end

    logger.info "its ok"
  end
  
  def current_admin_user
    if current_user&.is_admin?
      current_user
    end
  end
end
