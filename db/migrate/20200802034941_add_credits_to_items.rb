class AddCreditsToItems < ActiveRecord::Migration[6.0]
  def change
    add_column :items, :credits, :integer, default: 1, null: false
  end
end
