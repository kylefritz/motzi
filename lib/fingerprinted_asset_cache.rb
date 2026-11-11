# Lets browsers keep fingerprinted static files for a year.
#
# Files under /assets/ (Sprockets) and /vite/assets/ (Vite) have a content
# hash in their name, so a changed file always gets a new URL. Everything else
# in public/ (favicon.ico, the apple-touch icons, 500.html) keeps its name
# when it changes and must not be cached this way, which is why this is a
# middleware and not config.public_file_server.headers: that hash applies to
# every static file.
class FingerprintedAssetCache
  PATHS = %r{\A/(?:assets|vite/assets)/}
  CACHE_CONTROL = "public, max-age=#{365 * 24 * 60 * 60}, immutable".freeze
  CACHEABLE_STATUSES = [ 200, 206, 304 ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    if CACHEABLE_STATUSES.include?(status.to_i) && PATHS.match?(env["PATH_INFO"].to_s)
      headers.delete("Cache-Control") # Rack 3 headers are lowercase; drop a legacy-cased one
      headers["cache-control"] = CACHE_CONTROL
    end

    [ status, headers, body ]
  end
end
