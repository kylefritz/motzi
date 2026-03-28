class CreateDynoMetrics < ActiveRecord::Migration[7.2]
  def change
    create_table :dyno_metrics do |t|
      t.datetime :recorded_at, null: false
      t.string :dyno, null: false
      t.float :memory_total
      t.float :memory_rss
      t.float :memory_swap
      t.float :memory_quota
      t.integer :r14_count, default: 0
      t.text :errors_summary

      t.timestamps
    end

    add_index :dyno_metrics, :recorded_at
    add_index :dyno_metrics, [:dyno, :recorded_at]
  end
end
