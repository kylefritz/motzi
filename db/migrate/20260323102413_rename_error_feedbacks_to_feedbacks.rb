class RenameErrorFeedbacksToFeedbacks < ActiveRecord::Migration[7.2]
  def change
    rename_table :error_feedbacks, :feedbacks
    rename_column :feedbacks, :page_type, :source
  end
end
