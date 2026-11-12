class CaptureDynoMetricsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "capture_dyno_metrics"
  retry_on Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, LogDrain::ServerError,
           wait: :polynomially_longer, attempts: 3

  APP_NAME = "motzibread"
  # Matches the schedule (:03 and :33), so each run sees every sample once.
  WINDOW = 30.minutes

  # Heroku killed a dyno for using far more than its memory quota (R15).
  # Unlike R14 (a soft warning we expect and only count), this is an outage
  # for whatever the dyno was doing.
  class DynoKilled < StandardError; end

  def perform
    log_content = recent_logs
    return if log_content.nil?

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
        r15_count: metrics[:r15_count],
        errors_summary: metrics[:errors_summary]
      )
      report_r15s(dyno, metrics[:r15_lines])
    end

    Rails.logger.info("[CaptureDynoMetricsJob] Saved metrics for #{metrics_by_dyno.size} dyno(s)")
  end

  private

  # One error event per R15 line. The schedule matches WINDOW, so each line is
  # seen (and reported) once.
  def report_r15s(dyno, lines)
    lines.each do |line|
      Rails.error.report(DynoKilled.new("#{dyno} was killed by Heroku: #{line}"),
                         handled: true, severity: :error,
                         context: { source: "capture_dyno_metrics", dyno: dyno })
    end
  end

  # The log drain has the whole window. Heroku's log session only has the last
  # 1,500 lines, which can be just a few minutes when it's busy.
  def recent_logs
    return LogDrain.fetch(since: WINDOW.ago) if LogDrain.configured?

    api_key = ENV["HEROKU_API_KEY"]
    if api_key.blank?
      Rails.logger.warn("[CaptureDynoMetricsJob] Neither LOG_DRAIN_URL nor HEROKU_API_KEY is set — skipping")
      return
    end
    fetch_recent_logs(api_key)
  end

  def fetch_recent_logs(api_key)
    session = create_log_session(api_key)
    logplex_url = session["logplex_url"] || raise("LogSession response missing logplex_url")

    uri = URI(logplex_url)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
      response = http.request(Net::HTTP::Get.new(uri))
      raise "Logplex returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)
      response.body || ""
    end
  end

  def create_log_session(api_key)
    uri = URI("https://api.heroku.com/apps/#{APP_NAME}/log-sessions")
    request = Net::HTTP::Post.new(uri)
    request["Accept"] = "application/vnd.heroku+json; version=3"
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = { lines: 1500 }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
      http.request(request)
    end

    raise "Heroku LogSession API returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  # Parses Heroku log lines for memory samples and R14/R15 errors.
  # Returns max memory values per dyno, the R14 count, and the R15 count/lines.
  #
  # Memory sample format:
  #   source=web.1 dyno=heroku.123 sample#memory_total=635.12MB sample#memory_rss=504.00MB ...
  # R14 format:
  #   heroku[web.1]: Error R14 (Memory quota exceeded)
  # R15 format:
  #   heroku[web.1]: Error R15 (Memory quota vastly exceeded)
  def parse_log_lines(log_content)
    # Logplex bodies arrive as binary and occasionally contain invalid UTF-8;
    # unscrubbed bytes blow up the DynoMetric insert (PG::CharacterNotInRepertoire).
    log_content = log_content.dup.force_encoding(Encoding::UTF_8).scrub("?")
    samples = Hash.new { |h, k| h[k] = { memory_totals: [], memory_rss: [], memory_swaps: [], memory_quotas: [], r14_count: 0, r15_lines: [], errors: [] } }

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
      elsif line.include?("Error R15")
        dyno = line[/heroku\[(\S+)\]/, 1]
        next unless dyno
        samples[dyno][:r15_lines] << line[/Error R15.*/].strip.first(200)
        # Still listed with the dyno's errors, ahead of the 20-line cap.
        samples[dyno][:errors].unshift(line.strip.first(500))
      elsif line.match?(/(?:Error|Exception|FATAL)\b/) && !line.include?("sample#")
        next if line.include?("sentry") || line.include?("Discarding") || line.include?("rate limiting")
        dyno = line[/app\[(\S+)\]/, 1] || line[/heroku\[(\S+)\]/, 1]
        next unless dyno
        error_line = line.strip.first(500)
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
        r15_count: data[:r15_lines].size,
        r15_lines: data[:r15_lines],
        errors_summary: data[:errors].any? ? data[:errors].join("\n") : nil
      }
    end
  end
end
