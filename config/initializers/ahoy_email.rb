AhoyEmail.api = true

# ahoy_email 1.x only follows a click URL whose HMAC signature it wrote at send
# time, but redirects with a plain redirect_to, so Rails' open redirect
# protection 500s every link to an outside site (error_events #2785).
module AhoyEmailSignedRedirects
  def redirect_to(options = {}, response_options = {})
    super(options, response_options.merge(allow_other_host: true))
  end
end

Rails.application.config.to_prepare do
  Ahoy::MessagesController.prepend(AhoyEmailSignedRedirects)
end
