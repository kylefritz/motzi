class AddDayLimitsToMenuItems < ActiveRecord::Migration[6.0]
  def change
    add_column :menu_items, :day1_limit, :integer
    add_column :menu_items, :day2_limit, :integer
  end
end
