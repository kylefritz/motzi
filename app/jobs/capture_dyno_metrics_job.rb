class CaptureDynoMetricsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "capture_dyno_metrics"

  APP_NAME = "motzibread"

  def perform
    api_key = ENV["HEROKU_API_KEY"]
    if api_key.blank?
      Rails.logger.warn("[CaptureDynoMetricsJob] HEROKU_API_KEY not set — skipping")
      return
    end

    log_content = fetch_recent_logs(api_key)
    metrics_by_dyno = parse_log_lines(log_content)

    if metrics_by_dyno.empty?
      Rails.logger.info("[CaptureDynoMetricsJob] No memory samples found in recent logs")
      return
    end

    now = Time.current
    metrics_by_dyno.each do |dyno, metrics|
      DynoMetric.create!(
        recorded_at: now,
        dyno: dyno,
        memory_total: metrics[:memory_total],
        memory_rss: metrics[:memory_rss],
        memory_swap: metrics[:memory_swap],
        memory_quota: metrics[:memory_quota],
        r14_count: metrics[:r14_count],
        errors_summary: metrics[:errors_summary]
      )
    end

    Rails.logger.info("[CaptureDynoMetricsJob] Saved metrics for #{metrics_by_dyno.size} dyno(s)")
  end

  private

  def fetch_recent_logs(api_key)
    session = create_log_session(api_key)
    logplex_url = session["logplex_url"]

    uri = URI(logplex_url)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
      response = http.request(Net::HTTP::Get.new(uri))
      response.body || ""
    end
  end

  def create_log_session(api_key)
    uri = URI("https://api.heroku.com/apps/#{APP_NAME}/log-sessions")
    request = Net::HTTP::Post.new(uri)
    request["Accept"] = "application/vnd.heroku+json; version=3"
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = {lines: 1500}.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
      http.request(request)
    end

    raise "Heroku LogSession API returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  # Parses Heroku log lines for memory samples and R14 errors.
  # Returns max memory values per dyno and R14 count.
  #
  # Memory sample format:
  #   source=web.1 dyno=heroku.123 sample#memory_total=635.12MB sample#memory_rss=504.00MB ...
  # R14 format:
  #   heroku[web.1]: Error R14 (Memory quota exceeded)
  def parse_log_lines(log_content)
    samples = Hash.new { |h, k| h[k] = {memory_totals: [], memory_rss: [], memory_swaps: [], memory_quotas: [], r14_count: 0, errors: []} }

    log_content.each_line do |line|
      if line.include?("sample#memory_total=")
        dyno = line[/source=(\S+)/, 1]
        next unless dyno

        total = line[/sample#memory_total=([\d.]+)MB/, 1]&.to_f
        rss = line[/sample#memory_rss=([\d.]+)MB/, 1]&.to_f
        swap = line[/sample#memory_swap=([\d.]+)MB/, 1]&.to_f
        quota = line[/sample#memory_quota=([\d.]+)MB/, 1]&.to_f

        samples[dyno][:memory_totals] << total if total
        samples[dyno][:memory_rss] << rss if rss
        samples[dyno][:memory_swaps] << swap if swap
        samples[dyno][:memory_quotas] << quota if quota
      elsif line.include?("Error R14")
        dyno = line[/heroku\[(\S+)\]/, 1]
        samples[dyno][:r14_count] += 1 if dyno
      elsif line.match?(/Error|Exception|FATAL|ActionView::Template::Error|ActiveRecord/)
        # Skip Sentry noise and known non-errors
        next if line.include?("sentry") || line.include?("Discarding") || line.include?("rate limiting")
        dyno = line[/app\[(\S+)\]/, 1] || line[/heroku\[(\S+)\]/, 1]
        next unless dyno
        # Keep first 500 chars of each error, cap at 20 errors per dyno
        error_line = line.strip.last(500)
        samples[dyno][:errors] << error_line if samples[dyno][:errors].size < 20
      end
    end

    samples.transform_values do |data|
      {
        memory_total: data[:memory_totals].max,
        memory_rss: data[:memory_rss].max,
        memory_swap: data[:memory_swaps].max,
        memory_quota: data[:memory_quotas].last,
        r14_count: data[:r14_count],
        errors_summary: data[:errors].any? ? data[:errors].join("\n") : nil
      }
    end
  end
end
