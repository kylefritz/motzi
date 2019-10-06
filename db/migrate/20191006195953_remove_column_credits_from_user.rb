class RemoveColumnCreditsFromUser < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :credits
  end
end
