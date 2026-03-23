class TrimAnalyticsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "trim_analytics"

  def perform
    cutoff = 90.days.ago
    events_deleted = Ahoy::Event.where("time < ?", cutoff).delete_all
    visits_deleted = Ahoy::Visit.where("started_at < ?", cutoff).delete_all
    Rails.logger.info "[TrimAnalyticsJob] Deleted #{events_deleted} events and #{visits_deleted} visits older than #{cutoff.to_date}"
  end
end
