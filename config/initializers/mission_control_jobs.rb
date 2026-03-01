# /jobs is mounted behind Devise admin authentication in routes.rb.
# Disable Mission Control's built-in HTTP basic auth to avoid 401 responses
# when credentials are not configured.
MissionControl::Jobs.http_basic_auth_enabled = false

# Mission Control defaults to a silent logger. Keep it silent in development so
# web/worker output stays readable, but use the app logger in production.
MissionControl::Jobs.logger = Rails.logger if Rails.env.production?
