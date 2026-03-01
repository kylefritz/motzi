# /jobs is mounted behind Devise admin authentication in routes.rb.
# Disable Mission Control's built-in HTTP basic auth to avoid 401 responses
# when credentials are not configured.
MissionControl::Jobs.http_basic_auth_enabled = false
MissionControl::Jobs.logger = Rails.logger
