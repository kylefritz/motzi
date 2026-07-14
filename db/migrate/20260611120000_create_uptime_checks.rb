class CreateUptimeChecks < ActiveRecord::Migration[7.2]
  def change
    create_table :uptime_checks do |t|
      t.string :target, null: false
      t.string :url, null: false
      t.integer :status
      t.integer :latency_ms
      t.string :error
      t.boolean :up, null: false, default: false
      t.datetime :checked_at, null: false

      t.timestamps

      t.index [:target, :checked_at]
    end
  end
end
