class RenameTuesdayPickupToDay1Pickup < ActiveRecord::Migration[6.0]
  def change
    rename_column :users, :tuesday_pickup, :day1_pickup
  end
end
