class RegistrationsController < Devise::RegistrationsController
  include TurnstileVerifiable

  before_action :check_turnstile, only: :create

  private

  def check_turnstile
    return unless ENV["TURNSTILE_SECRET_KEY"].present?

    token = params["cf-turnstile-response"]
    reject_as_bot unless verify_turnstile_token(token, remoteip: request.remote_ip)
  end

  def reject_as_bot
    set_flash_message(:alert, :turnstile_failed)
    redirect_to new_registration_path(resource_name)
  end
end
