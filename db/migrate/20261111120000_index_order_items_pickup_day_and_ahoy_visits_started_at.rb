# order_items.pickup_day_id: Menu#item_counts groups by it on every menu load,
# and PickupDay looks up its order items by it.
# ahoy_visits.started_at: TrimAnalyticsJob deletes by it nightly, the activity
# feed counts visits per day, and the admin Visits page sorts on it.
#
# Built concurrently so neither table is locked against writes.
class IndexOrderItemsPickupDayAndAhoyVisitsStartedAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :order_items, :pickup_day_id, algorithm: :concurrently, if_not_exists: true
    add_index :ahoy_visits, :started_at, algorithm: :concurrently, if_not_exists: true
  end
end
