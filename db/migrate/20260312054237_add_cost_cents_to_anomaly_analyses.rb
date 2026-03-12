class AddCostCentsToAnomalyAnalyses < ActiveRecord::Migration[7.2]
  def change
    add_column :anomaly_analyses, :cost_cents, :integer
  end
end
