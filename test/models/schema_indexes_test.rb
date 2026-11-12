require "test_helper"

# Columns the app filters or joins on in hot paths; without an index each is a
# sequential scan.
class SchemaIndexesTest < ActiveSupport::TestCase
  # Menu#item_counts groups order_items by pickup day on every menu load, and
  # PickupDay checks for order items before it can be deleted.
  test "order_items.pickup_day_id is indexed" do
    assert ActiveRecord::Base.connection.index_exists?(:order_items, :pickup_day_id)
  end

  # TrimAnalyticsJob deletes by started_at nightly and the activity feed
  # counts visits per day.
  test "ahoy_visits.started_at is indexed" do
    assert ActiveRecord::Base.connection.index_exists?(:ahoy_visits, :started_at)
  end
end
