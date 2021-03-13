class AddPickupDayIdToAhoyMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :ahoy_messages, :pickup_day_id, :bigint
  end
end
