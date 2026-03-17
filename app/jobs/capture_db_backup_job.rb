class CaptureDbBackupJob < ApplicationJob
  queue_as :default

  # Captures a manual Heroku Postgres backup via the heroku-api-postgres gem.
  # Requires HEROKU_API_KEY and HEROKU_APP_NAME env vars (both set automatically by Heroku).
  #
  # API docs: https://devcenter.heroku.com/articles/heroku-postgres-backups
  def perform
    api_key = ENV["HEROKU_API_KEY"]
    app_name = ENV["HEROKU_APP_NAME"]

    if api_key.blank? || app_name.blank?
      Rails.logger.warn("[CaptureDbBackupJob] Skipping: HEROKU_API_KEY or HEROKU_APP_NAME not available")
      return
    end

    addon_id = resolve_addon_id(api_key, app_name)
    if addon_id.blank?
      Rails.logger.error("[CaptureDbBackupJob] Could not resolve Postgres addon ID")
      return
    end

    client = Heroku::Api::Postgres.connect(api_key)
    result = client.backups.capture(addon_id)

    Rails.logger.info("[CaptureDbBackupJob] Backup initiated: #{result}")
  end

  private

  # Resolves the Heroku Postgres addon ID from the Platform API.
  def resolve_addon_id(api_key, app_name)
    return ENV["HEROKU_POSTGRESQL_ADDON_ID"] if ENV["HEROKU_POSTGRESQL_ADDON_ID"].present?

    uri = URI("https://api.heroku.com/apps/#{app_name}/addons")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/vnd.heroku+json; version=3"
    request["Authorization"] = "Bearer #{api_key}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

    return nil unless response.is_a?(Net::HTTPSuccess)

    addons = JSON.parse(response.body)
    pg_addon = addons.find { |a| a.dig("addon_service", "name") == "heroku-postgresql" }
    pg_addon&.dig("id")
  end
end
