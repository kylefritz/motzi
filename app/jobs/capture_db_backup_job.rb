class CaptureDbBackupJob < ApplicationJob
  queue_as :default

  # Captures a manual Heroku Postgres backup via the heroku-api-postgres gem.
  # Requires HEROKU_API_KEY and HEROKU_APP_NAME env vars (both set automatically by Heroku).
  #
  # API docs: https://devcenter.heroku.com/articles/heroku-postgres-backups
  def perform
    api_key = ENV['HEROKU_API_KEY']
    app_name = ENV['HEROKU_APP_NAME']

    if api_key.blank? || app_name.blank?
      Rails.logger.warn('[CaptureDbBackupJob] Skipping: HEROKU_API_KEY or HEROKU_APP_NAME not available')
      return
    end

    check_api_key_health!(api_key)
    capture_backup!(api_key, app_name)
  end

  private

  def capture_backup!(api_key, app_name)
    addon_id = resolve_addon_id(api_key, app_name)
    if addon_id.blank?
      Rails.logger.error('[CaptureDbBackupJob] Could not resolve Postgres addon ID')
      return
    end

    client = Heroku::Api::Postgres.connect(api_key)
    result = client.backups.capture(addon_id)
    Rails.logger.info("[CaptureDbBackupJob] Backup initiated: #{result}")
  end

  # Checks if the Heroku API key is still valid and warns if expiring within 14 days.
  def check_api_key_health!(api_key)
    response = heroku_api_get('/oauth/authorizations', api_key)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("[CaptureDbBackupJob] Heroku API key is invalid (HTTP #{response.code})")
      BackupAlertMailer.api_key_expired.deliver_now
      raise 'Heroku API key is invalid — backup cannot proceed'
    end

    warn_if_expiring(api_key, JSON.parse(response.body))
  end

  def warn_if_expiring(api_key, authorizations)
    current_auth = authorizations.find { |a| a.dig('access_token', 'token') == api_key }
    return unless current_auth&.dig('access_token', 'expires_in')

    expires_in_days = current_auth['access_token']['expires_in'] / 86_400
    return unless expires_in_days <= 14

    Rails.logger.warn("[CaptureDbBackupJob] Heroku API key expires in #{expires_in_days} days!")
    BackupAlertMailer.api_key_expiring(expires_in_days).deliver_now
  end

  def resolve_addon_id(api_key, app_name)
    return ENV['HEROKU_POSTGRESQL_ADDON_ID'] if ENV['HEROKU_POSTGRESQL_ADDON_ID'].present?

    response = heroku_api_get("/apps/#{app_name}/addons", api_key)
    return nil unless response.is_a?(Net::HTTPSuccess)

    addons = JSON.parse(response.body)
    pg_addon = addons.find { |a| a.dig('addon_service', 'name') == 'heroku-postgresql' }
    pg_addon&.dig('id')
  end

  def heroku_api_get(path, api_key)
    uri = URI("https://api.heroku.com#{path}")
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/vnd.heroku+json; version=3'
    request['Authorization'] = "Bearer #{api_key}"
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
  end
end
