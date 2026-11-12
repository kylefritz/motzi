# R14 (soft, in swap) was counted; R15 (the dyno is killed) was not.
class AddR15CountToDynoMetrics < ActiveRecord::Migration[8.1]
  def change
    add_column :dyno_metrics, :r15_count, :integer, default: 0
  end
end
