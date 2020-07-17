class MenuItemAttrs < ActiveRecord::Migration[6.0]
  def change
    remove_column :menu_items, :is_add_on, :boolean

    add_column :menu_items, :subscriber_only, :boolean, default: false
    add_column :menu_items, :day1, :boolean, default: true
    add_column :menu_items, :day2, :boolean, default: true
  end
end
