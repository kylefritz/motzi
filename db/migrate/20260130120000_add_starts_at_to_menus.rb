class AddStartsAtToMenus < ActiveRecord::Migration[6.1]
  def change
    add_column :menus, :starts_at, :datetime
  end
end
