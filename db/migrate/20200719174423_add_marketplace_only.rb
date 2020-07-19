class AddMarketplaceOnly < ActiveRecord::Migration[6.0]
  def change
    add_column :menu_items, :marketplace_only, :boolean, default: false
  end
end
