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
    | /sitemap\.(xml|txt)
  }x

  blocklist("scanner paths") do |req|
    SCANNER_PATHS.match?(req.path)
  end
end

Rack::Attack.blocklisted_responder = ->(_req) { [404, { "Content-Type" => "text/plain" }, ["Not Found"]] }
