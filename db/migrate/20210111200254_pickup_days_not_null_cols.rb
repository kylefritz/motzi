class PickupDaysNotNullCols < ActiveRecord::Migration[6.0]
  def change
    change_column_null :pickup_days, :pickup_at, false
    change_column_null :pickup_days, :order_deadline_at, false
  end
end
