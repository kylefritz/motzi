class CreateAnalysisReplies < ActiveRecord::Migration[7.2]
  def change
    create_table :analysis_replies do |t|
      t.references :anomaly_analysis, null: false, foreign_key: true, index: true
      t.references :user, null: true, foreign_key: true, index: true
      t.string :author_email, null: false
      t.string :author_name
      t.text :body, null: false
      t.string :message_id
      t.integer :source, null: false, default: 0

      t.timestamps
    end

    add_index :analysis_replies, :message_id, unique: true
  end
end
