class AddEmailPreferencesToUsers < ActiveRecord::Migration[7.2]
  def change
    rename_column :users, :subscriber, :receive_weekly_menu
    add_column :users, :receive_havent_ordered_reminder, :boolean, default: true, null: false
    add_column :users, :receive_day_of_reminder, :boolean, default: true, null: false
  end
end
