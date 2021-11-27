class AddSortOrderToMenuItems < ActiveRecord::Migration[6.0]
  def change
    add_column :menu_items, :sort_order, :integer
  end
end
