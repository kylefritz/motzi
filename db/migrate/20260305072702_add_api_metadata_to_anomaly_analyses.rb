class AddApiMetadataToAnomalyAnalyses < ActiveRecord::Migration[7.2]
  def change
    add_column :anomaly_analyses, :cache_creation_input_tokens, :integer
    add_column :anomaly_analyses, :cache_read_input_tokens, :integer
    add_column :anomaly_analyses, :stop_reason, :string
    add_column :anomaly_analyses, :api_model, :string
  end
end
