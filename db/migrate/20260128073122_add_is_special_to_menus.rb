class AddIsSpecialToMenus < ActiveRecord::Migration[6.1]
  def change
    add_column :menus, :is_special, :boolean, null: false, default: false
  end
end
