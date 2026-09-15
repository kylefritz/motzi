# At DNS cutover, set CANONICAL_HOST=motzibread.com on Heroku so
# motzibread.herokuapp.com 301s to the custom domain. No-op while unset.
if ENV["CANONICAL_HOST"].present?
  require "canonical_host_redirect"

  Rails.application.config.middleware.insert_before Rack::Runtime,
                                                    CanonicalHostRedirect,
                                                    ENV["CANONICAL_HOST"]
end
