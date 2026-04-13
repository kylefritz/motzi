class AddEmailMessageIdToAnomalyAnalyses < ActiveRecord::Migration[7.2]
  def change
    add_column :anomaly_analyses, :email_message_id, :string
    add_index :anomaly_analyses, :email_message_id, unique: true
  end
end
