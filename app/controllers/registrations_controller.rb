class RegistrationsController < Devise::RegistrationsController
  before_action :verify_turnstile, only: :create

  private

  def verify_turnstile
    return unless ENV["TURNSTILE_SECRET_KEY"].present?

    token = params["cf-turnstile-response"]
    return reject_as_bot if token.blank?

    response = Net::HTTP.post_form(
      URI("https://challenges.cloudflare.com/turnstile/v0/siteverify"),
      { secret: ENV["TURNSTILE_SECRET_KEY"], response: token, remoteip: request.remote_ip }
    )
    result = JSON.parse(response.body)

    reject_as_bot unless result["success"]
  end

  def reject_as_bot
    set_flash_message(:alert, :turnstile_failed)
    redirect_to new_registration_path(resource_name)
  end
end
