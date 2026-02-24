class AddMenuTypeToMenus < ActiveRecord::Migration[6.1]
  def change
    add_column :menus, :menu_type, :string, null: false, default: 'regular'
    remove_index :menus, name: 'index_menus_on_week_id'
    add_index :menus, [:week_id, :menu_type], unique: true,
              name: 'index_menus_on_week_id_and_menu_type'
  end
end
