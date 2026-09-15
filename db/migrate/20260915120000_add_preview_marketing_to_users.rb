class AddPreviewMarketingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :preview_marketing, :boolean, default: false, null: false
  end
end
