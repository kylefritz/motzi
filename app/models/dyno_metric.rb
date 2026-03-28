class DynoMetric < ApplicationRecord
  validates :recorded_at, :dyno, presence: true

  # Returns a hash keyed by dyno name with avg/max memory and R14 totals.
  #   { "web.1" => { avg_memory_total: 340, max_memory_total: 504, memory_quota: 512, total_r14: 2 }, ... }
  def self.summary_for_period(start_time, end_time)
    records = where(recorded_at: start_time..end_time)
    records.group_by(&:dyno).transform_values do |metrics|
      totals = metrics.map(&:memory_total).compact
      {
        avg_memory_total: totals.any? ? (totals.sum / totals.size).round : 0,
        max_memory_total: totals.max&.round || 0,
        max_memory_rss: metrics.map(&:memory_rss).compact.max&.round,
        max_memory_swap: metrics.map(&:memory_swap).compact.max&.round,
        memory_quota: metrics.last.memory_quota&.round,
        total_r14: metrics.sum(&:r14_count),
        sample_count: metrics.size,
        errors: metrics.filter_map(&:errors_summary).flat_map { |s| s.lines.map(&:strip) }.uniq.first(20)
      }
    end
  end
end
