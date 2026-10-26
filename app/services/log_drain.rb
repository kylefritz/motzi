# Reads production logs back from the log drain: a Cloudflare Worker that
# Heroku streams logs to, which keeps 30 days in R2
# (cloudflare/workers/log-drain). Heroku itself only keeps the last 1,500
# lines. Lines come back in the `heroku logs` format.
class LogDrain
  class Error < StandardError; end
  # The worker answers 503 when Cloudflare storage hiccups; worth retrying.
  class ServerError < Error; end

  # Each response covers about 40 minutes of stored logs; longer windows page
  # through X-Next-Cursor.
  MAX_PAGES = 100

  def self.configured?
    ENV["LOG_DRAIN_URL"].present? && ENV["LOG_DRAIN_READ_TOKEN"].present?
  end

  def self.fetch(since:, until_time: nil, query: nil)
    new.fetch(since:, until_time:, query:)
  end

  def fetch(since:, until_time: nil, query: nil)
    params = { since: since.utc.iso8601(3) }
    params[:until] = until_time.utc.iso8601(3) if until_time
    params[:q] = query if query.present?

    body = +""
    cursor = nil
    MAX_PAGES.times do
      response = get(cursor ? params.merge(cursor: cursor) : params)
      body << response.body.to_s
      cursor = response["X-Next-Cursor"]
      return body if cursor.blank?
    end
    Rails.logger.warn("[LogDrain] Stopped after #{MAX_PAGES} pages; the window is too long")
    body
  end

  private

  def get(params)
    uri = URI("#{ENV.fetch("LOG_DRAIN_URL")}/logs")
    uri.query = URI.encode_www_form(params)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{ENV.fetch("LOG_DRAIN_READ_TOKEN")}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 30) do |http|
      http.request(request)
    end
    raise ServerError, "Log drain returned #{response.code}" if response.is_a?(Net::HTTPServerError)
    raise Error, "Log drain returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    response
  end
end
