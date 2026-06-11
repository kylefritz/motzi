require "net/http"

# Pulls aggregate deliverability stats (bounces, blocks, spam reports) from the
# SendGrid Stats API so the anomaly report has real data instead of guessing
# about deliverability from open rates alone.
#
# Auth: prefers SENDGRID_API_KEY; falls back to SENDGRID_PASSWORD when
# SENDGRID_USERNAME is "apikey" (modern SendGrid SMTP auth — the password *is*
# an API key). Returns nil when no key is configured or the request fails.
class SendgridStats
  ENDPOINT = URI("https://api.sendgrid.com/v3/stats")
  METRICS = %i[requests delivered bounces blocks spam_reports invalid_emails].freeze

  def self.api_key
    return ENV["SENDGRID_API_KEY"] if ENV["SENDGRID_API_KEY"].present?
    return ENV["SENDGRID_PASSWORD"] if ENV["SENDGRID_USERNAME"] == "apikey" && ENV["SENDGRID_PASSWORD"].present?

    nil
  end

  def self.for_period(start_date, end_date)
    key = api_key
    return nil unless key

    uri = ENDPOINT.dup
    uri.query = URI.encode_www_form(
      start_date: start_date.to_date.iso8601,
      end_date: [end_date.to_date, Date.current].min.iso8601,
      aggregated_by: "day"
    )

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{key}"
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn "[SendgridStats] API returned #{response.code}: #{response.body.to_s.first(200)}"
      return nil
    end

    totals = METRICS.index_with { 0 }
    JSON.parse(response.body).each do |day|
      day["stats"].to_a.each do |stat|
        metrics = stat["metrics"] || {}
        METRICS.each { |m| totals[m] += metrics[m.to_s].to_i }
      end
    end
    totals
  rescue StandardError => e
    Rails.logger.warn "[SendgridStats] #{e.class}: #{e.message}"
    nil
  end
end
