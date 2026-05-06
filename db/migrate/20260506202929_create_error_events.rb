class CreateErrorEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :error_events do |t|
      t.string :fingerprint, null: false
      t.string :source, null: false
      t.string :error_class
      t.text :message
      t.text :backtrace
      t.string :url
      t.string :http_method
      t.integer :status_code
      t.string :request_id
      t.jsonb :request_data, default: {}, null: false
      t.jsonb :context, default: {}, null: false
      t.references :user, foreign_key: true
      t.string :environment
      t.string :release
      t.datetime :occurred_at, null: false
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :error_events, [:fingerprint, :occurred_at]
    add_index :error_events, :occurred_at
    add_index :error_events, :resolved_at
    add_index :error_events, :source
  end
end
