# Postgres 18's btree skip scan lets index_dyno_metrics_on_dyno_and_recorded_at
# serve recorded_at-only filters (DynoMetric.summary_for_period, TrimAnalyticsJob)
# because dyno has only a handful of distinct values.
class RemoveRedundantDynoMetricsRecordedAtIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :dyno_metrics, :recorded_at, name: "index_dyno_metrics_on_recorded_at"
  end
end
