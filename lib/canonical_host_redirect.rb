# 301s any request whose host doesn't match the canonical host (e.g.
# motzibread.herokuapp.com after the DNS cutover to motzibread.com).
# Health checks are exempt so Heroku/uptime probes keep hitting the dyno
# directly, and so are the machine-to-machine POSTs (the Stripe webhook and
# the reply-ingress worker): they don't follow a 301, so redirecting them
# would silently drop every delivery.
class CanonicalHostRedirect
  EXEMPT_PATHS = %r{\A/(health|stripe/webhooks\z|reply_ingress\z)}

  def initialize(app, host)
    @app = app
    @host = host
  end

  def call(env)
    request = Rack::Request.new(env)
    return @app.call(env) if request.host == @host || EXEMPT_PATHS.match?(request.path)

    location = "https://#{@host}#{request.fullpath}"
    [ 301, { "Content-Type" => "text/html", "Location" => location }, [] ]
  end
end
