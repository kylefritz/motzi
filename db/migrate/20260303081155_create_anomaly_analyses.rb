class CreateAnomalyAnalyses < ActiveRecord::Migration[7.2]
  def change
    create_table :anomaly_analyses do |t|
      t.string :week_id, null: false
      t.text :result, null: false
      t.text :prompt_used
      t.string :model_used
      t.integer :input_tokens
      t.integer :output_tokens
      t.string :trigger, null: false
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end
    add_index :anomaly_analyses, :week_id
  end
end
