class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  before_action :set_paper_trail_whodunnit
  before_action :authenticate_user!
  before_action :set_raven_context
  before_action :push_gon
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def set_raven_context
    unless Rails.env.test?
      Raven.user_context(id: current_user&.id, email: current_user&.email, is_admin: current_user&.is_admin)
      Raven.extra_context(params: params.to_unsafe_h, url: request.url)
    end
  end

  def user_for_paper_trail
    current_user&.id
  end

  def redirect_unless_user_is_admin!
    # used by active admin to keep out non-admins
    unless current_user&.is_admin?
      logger.info "redirect_unless_user_is_admin: its NOT ok"
      return redirect_to '/', alert: 'you must be an admin'
    end
  end

  def current_admin_user
    if current_user&.is_admin?
      current_user
    end
  end

  def push_gon
    gon.push({
      stripe_api_key: ENV['STRIPE_PUBLISHABLE_KEY'],
      js_tracking: Setting.shop.js_tracking,
    })
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :phone, :opt_in, :subscriber])
  end
end
