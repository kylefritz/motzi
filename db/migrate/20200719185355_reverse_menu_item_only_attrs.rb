class ReverseMenuItemOnlyAttrs < ActiveRecord::Migration[6.0]
  def change
    add_column :menu_items, :subscriber, :boolean, default: true
    add_column :menu_items, :marketplace, :boolean, default: true

    remove_column :menu_items, :subscriber_only, :boolean, default: false
    remove_column :menu_items, :marketplace_only, :boolean, default: false
  end
end
