class AddOverallStatusToAnomalyAnalyses < ActiveRecord::Migration[7.2]
  def change
    add_column :anomaly_analyses, :overall_status, :string
  end
end
