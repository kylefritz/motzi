class AddArchivedAtToItems < ActiveRecord::Migration[7.2]
  def change
    add_column :items, :archived_at, :datetime
  end
end
