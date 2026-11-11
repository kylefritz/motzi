# Block scanner / bot traffic at the rack layer so it never reaches Rails
# routing and never shows up in the logs as RoutingError noise.
class Rack::Attack
  # Motzi has no legitimate .php / .zip / .sql / .bak endpoints and no WordPress
  # or Laravel install, so these are all scanner probes.
  SCANNER_PATHS = %r{
    \.php(\?|/|$)                              # PHP probes
    | /wp[-_](admin|content|login|includes)    # WordPress paths
    | /(laravel|telescope)                     # Laravel paths
    | \.(zip|tar|tar\.gz|tgz|rar|7z|sql|bak|backup)$  # backup archive probes
    | /\.env
    | /\.git
    | /xmlrpc
    | /sitemap\.txt                            # we only serve /sitemap.xml
  }x

  blocklist("scanner paths") do |req|
    SCANNER_PATHS.match?(req.path)
  end

  # Rails routes "/contact", "/contact/", "/contact.json" and so on to the same
  # action, so the throttles below match the path with any format suffix or
  # trailing slash.
  def self.path_matches?(req, path)
    req.path.match?(%r{\A#{Regexp.escape(path)}(\.\w+)?/?\z})
  end

  # Limit contact form submissions to 5 per hour per IP. The form is public, so
  # this is the main spam mitigation alongside the view-layer honeypot field.
  throttle("contact form per ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && path_matches?(req, "/contact")
  end

  # Feedback forms (error pages, the menu's "Share feedback") email the bakery
  # and some skip Turnstile, so they get the same limit.
  throttle("feedback per ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && path_matches?(req, "/api/feedbacks")
  end

  # uid sign-in links (?uid=<hashid>, UserHashidable) are short bearer
  # credentials, so guessing them is limited: after 20 uids that match no
  # member within a minute, every request carrying a uid from that IP is
  # refused for a minute. Refusing only the wrong guesses would still tell a
  # guesser which uids are right. Requests with a member's real uid don't
  # count, and requests without a uid are never affected.
  UID_GUESSING = "uid guessing per ip".freeze
  UID_MAX_FAILED_LOOKUPS = 20

  blocklist(UID_GUESSING) do |req|
    uid = uid_param(req)
    next false if uid.blank?

    Allow2Ban.filter("uid:#{req.ip}", maxretry: UID_MAX_FAILED_LOOKUPS, findtime: 1.minute, bantime: 1.minute) do
      User.find_by_hashid(uid).nil?
    end
  end

  # The uid as the controllers will see it: from the query string, a form
  # body or a JSON body (the menu app posts JSON).
  def self.uid_param(req)
    uid = ActionDispatch::Request.new(req.env).params[:uid]
    uid.to_s if uid.is_a?(String) || uid.is_a?(Integer)
  rescue StandardError
    nil # unparseable params: the app rejects them itself, as it does without this check
  end
end

Rack::Attack.blocklisted_responder = lambda do |req|
  if req.env["rack.attack.matched"] == Rack::Attack::UID_GUESSING
    [ 429, { "Content-Type" => "text/plain" }, [ "Too Many Requests" ] ]
  else
    [ 404, { "Content-Type" => "text/plain" }, [ "Not Found" ] ]
  end
end
Rack::Attack.throttled_responder = ->(_req) { [ 429, { "Content-Type" => "text/plain" }, [ "Too Many Requests" ] ] }
