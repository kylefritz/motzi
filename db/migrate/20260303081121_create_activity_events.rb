class CreateActivityEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :activity_events do |t|
      t.string :action, null: false
      t.string :week_id, null: false
      t.string :description, null: false
      t.jsonb :metadata, default: {}
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
    add_index :activity_events, :week_id
    add_index :activity_events, :action
  end
end
