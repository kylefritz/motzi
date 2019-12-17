class RenameIsFirstHalf < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :is_first_half, :tuesday_pickup
  end
end
