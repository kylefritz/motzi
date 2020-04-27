class RmDay1PickupFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :day1_pickup, :boolean, null: false
  end
end
