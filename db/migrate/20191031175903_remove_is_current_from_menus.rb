class RemoveIsCurrentFromMenus < ActiveRecord::Migration[6.0]
  def change
    remove_column :menus, :is_current
  end
end
