class AddDeadlineToMenus < ActiveRecord::Migration[6.0]
  def change
    add_column :menus, :day1_pickup_at, :date
    add_column :menus, :day1_deadline, :datetime

    add_column :menus, :day2_pickup_at, :date
    add_column :menus, :day2_deadline, :datetime
  end
end
