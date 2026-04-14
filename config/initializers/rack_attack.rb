# Block scanner / bot traffic at the rack layer so it never reaches Rails
# routing and never shows up in the logs as RoutingError noise.
class Rack::Attack
  SCANNER_PATHS = %r{
    \.php(\?|/|$)            # anything .php
    | /wp-(admin|content|login|includes)
    | /\.env
    | /\.git
    | /xmlrpc
    | /sitemap\.(xml|txt)
  }x

  blocklist("scanner paths") do |req|
    SCANNER_PATHS.match?(req.path)
  end
end

Rack::Attack.blocklisted_responder = ->(_req) { [404, { "Content-Type" => "text/plain" }, ["Not Found"]] }
