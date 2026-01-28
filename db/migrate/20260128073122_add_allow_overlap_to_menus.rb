class AddAllowOverlapToMenus < ActiveRecord::Migration[6.1]
  def change
    add_column :menus, :allow_overlap, :boolean, null: false, default: false
  end
end
