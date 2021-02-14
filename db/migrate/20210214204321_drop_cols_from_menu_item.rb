class DropColsFromMenuItem < ActiveRecord::Migration[6.0]
  def change
    remove_column :menu_items, :day1, :boolean, default: true
    remove_column :menu_items, :day2, :boolean, default: true
    remove_column :menu_items, :day1_limit, :integer
    remove_column :menu_items, :day2_limit, :integer
  end
end
