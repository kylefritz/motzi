require "net/http"

# A live "is the site up right now?" check included in the anomaly analysis
# prompt, so the report never has to ask the operator to "verify the site was
# accessible". Probes UPTIME_PROBE_URL (defaults to the public site in
# production); returns nil when no URL is configured (dev/test).
class UptimeProbe
  def self.url
    return ENV["UPTIME_PROBE_URL"] if ENV["UPTIME_PROBE_URL"].present?
    return nil unless Rails.env.production?

    domain = ENV["HEROKU_APP_NAME"] ? "#{ENV['HEROKU_APP_NAME']}.herokuapp.com" : ShopConfig.shop.app_domain
    "https://#{domain}"
  end

  def self.check(target = url)
    return nil if target.blank?

    uri = URI(target)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
      # request_uri keeps the query string — a configured probe URL like
      # /health?token=... must be requested verbatim (PR #337 review).
      http.request(Net::HTTP::Get.new(uri.request_uri))
    end
    latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round

    { url: target, status: response.code.to_i, latency_ms: latency_ms, checked_at: Time.current }
  rescue StandardError => e
    { url: target, status: nil, error: "#{e.class}: #{e.message}", checked_at: Time.current }
  end
end
