class RequireDeadlineOnMenus < ActiveRecord::Migration[6.0]
  def change
    change_column_null :menus, :day1_pickup_at, false
    change_column_null :menus, :day1_deadline, false

    change_column_null :menus, :day2_pickup_at, false
    change_column_null :menus, :day2_deadline, false
  end
end
