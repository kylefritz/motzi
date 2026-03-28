module TurnstileVerifiable
  extend ActiveSupport::Concern

  TURNSTILE_VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  private

  def verify_turnstile_token(token, remoteip: nil)
    return false if token.blank?

    secret = ENV["TURNSTILE_SECRET_KEY"]
    return true if secret.blank?

    params = { secret: secret, response: token }
    params[:remoteip] = remoteip if remoteip

    response = Net::HTTP.post_form(URI(TURNSTILE_VERIFY_URL), params)
    JSON.parse(response.body)["success"] == true
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
    Rails.logger.error("[Turnstile] Network error: #{e.class}: #{e.message}")
    true # fail open: don't block users because Cloudflare is unreachable
  rescue StandardError => e
    Rails.logger.error("[Turnstile] Unexpected error: #{e.class}: #{e.message}")
    false
  end
end
