class CaptureDbBackupJob < ApplicationJob
  queue_as :default

  APP_NAME = "motzibread"

  # Captures a manual Heroku Postgres backup via the heroku-api-postgres gem.
  # Requires HEROKU_API_KEY env var.
  #
  # API docs: https://devcenter.heroku.com/articles/heroku-postgres-backups
  def perform
    api_key = ENV["HEROKU_API_KEY"]
    raise "HEROKU_API_KEY not set — cannot capture backup" if api_key.blank?

    check_api_key_health!(api_key)
    capture_backup!(api_key)
  end

  private

  def capture_backup!(api_key)
    addon_id = resolve_addon_id(api_key)
    raise "Could not resolve Postgres addon ID" if addon_id.blank?

    client = Heroku::Api::Postgres.connect(api_key)
    result = client.backups.capture(addon_id)
    Rails.logger.info("[CaptureDbBackupJob] Backup initiated: #{result}")
  end

  # Checks if the Heroku API key is still valid and warns if expiring within 14 days.
  def check_api_key_health!(api_key)
    response = heroku_api_get("/oauth/authorizations", api_key)

    if response.code.in?(%w[401 403])
      Rails.logger.error("[CaptureDbBackupJob] Heroku API key is invalid (HTTP #{response.code})")
      BackupAlertMailer.api_key_expired.deliver_now
      raise "Heroku API key is invalid — backup cannot proceed"
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise "Heroku API returned HTTP #{response.code} checking authorizations"
    end

    warn_if_expiring(api_key, JSON.parse(response.body))
  end

  def warn_if_expiring(api_key, authorizations)
    current_auth = authorizations.find { |a| a.dig("access_token", "token") == api_key }
    return unless current_auth&.dig("access_token", "expires_in")

    expires_in_days = current_auth["access_token"]["expires_in"] / 86_400
    return unless expires_in_days <= 14

    Rails.logger.warn("[CaptureDbBackupJob] Heroku API key expires in #{expires_in_days} days!")
    BackupAlertMailer.api_key_expiring(expires_in_days).deliver_now
  end

  # Resolve the primary Postgres addon via the DATABASE attachment name,
  # which Heroku guarantees points to the primary database.
  def resolve_addon_id(api_key)
    return ENV["HEROKU_POSTGRESQL_ADDON_ID"] if ENV["HEROKU_POSTGRESQL_ADDON_ID"].present?

    response = heroku_api_get("/apps/#{APP_NAME}/addon-attachments", api_key)
    raise "Failed to list addon attachments (HTTP #{response.code})" unless response.is_a?(Net::HTTPSuccess)

    attachments = JSON.parse(response.body)
    primary = attachments.find { |a| a["name"] == "DATABASE" }
    primary&.dig("addon", "id")
  end

  def heroku_api_get(path, api_key)
    uri = URI("https://api.heroku.com#{path}")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/vnd.heroku+json; version=3"
    request["Authorization"] = "Bearer #{api_key}"
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
  end
end
