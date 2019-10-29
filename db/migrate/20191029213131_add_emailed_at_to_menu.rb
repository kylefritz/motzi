class AddEmailedAtToMenu < ActiveRecord::Migration[6.0]
  def change
    add_column :menus, :emailed_at, :datetime
  end
end
