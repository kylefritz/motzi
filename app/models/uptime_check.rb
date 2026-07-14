# A recorded result of one scheduled HTTP probe of the site (see
# UptimeSchedule for what gets probed when, UptimeCheckJob for the runner).
class UptimeCheck < ApplicationRecord
  # Never raised — used as the exception class for Rails.error.report so
  # outages land in error_events (admin UI + weekly feed) without paging.
  class OutageError < StandardError; end

  UP_STATUSES = (200..399)

  validates :target, :url, :checked_at, presence: true

  scope :for_period, ->(range) { where(checked_at: range) }

  def self.record!(target:, probe:)
    create!(
      target: target.to_s,
      url: probe[:url],
      status: probe[:status],
      latency_ms: probe[:latency_ms],
      error: probe[:error],
      up: probe[:status].present? && UP_STATUSES.cover?(probe[:status]),
      checked_at: probe[:checked_at]
    )
  end

  # { "menu" => { checks:, up_count:, pct_up:, avg_latency_ms:, max_latency_ms:, failures: [UptimeCheck] } }
  def self.summary_for_period(period_start, period_end)
    for_period(period_start..period_end).order(:checked_at).group_by(&:target).transform_values do |rows|
      up_count = rows.count(&:up)
      latencies = rows.filter_map(&:latency_ms)
      {
        checks: rows.size,
        up_count: up_count,
        pct_up: (up_count.to_f / rows.size * 100).round(1),
        avg_latency_ms: latencies.any? ? (latencies.sum.to_f / latencies.size).round : nil,
        max_latency_ms: latencies.max,
        failures: rows.reject(&:up)
      }
    end
  end

  # A single failed check is data, not an incident. Report once per outage,
  # on the second consecutive failure — never again until the target recovers.
  def report_outage_if_needed
    return if up

    prior = self.class.where(target: target).where("checked_at < ?", checked_at)
                .order(checked_at: :desc).limit(2).to_a
    return if prior.first.nil? || prior.first.up # first failure: wait for confirmation
    return if prior.second && !prior.second.up   # outage already reported

    Rails.error.report(
      OutageError.new("Uptime: #{target} down 2 consecutive checks (GET #{url} → #{failure_detail})"),
      handled: true,
      severity: :warning,
      context: { target: target, url: url, status: status, probe_error: error }
    )
  end

  def failure_detail
    status ? "HTTP #{status}" : error.to_s
  end
end
