class AddIsCurrentToMenu < ActiveRecord::Migration[6.0]
  def change
    add_column :menus, :is_current, :boolean, null: false, default: false
  end
end
