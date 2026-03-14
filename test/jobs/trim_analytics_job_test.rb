require 'test_helper'

class TrimAnalyticsJobTest < ActiveJob::TestCase
  test "deletes events and visits older than 90 days" do
    old_visit = Ahoy::Visit.create!(started_at: 91.days.ago, visitor_token: "old", visit_token: "old")
    new_visit = Ahoy::Visit.create!(started_at: 89.days.ago, visitor_token: "new", visit_token: "new")

    Ahoy::Event.create!(visit: old_visit, name: "old_event", time: 91.days.ago)
    Ahoy::Event.create!(visit: new_visit, name: "new_event", time: 89.days.ago)

    TrimAnalyticsJob.perform_now

    assert_not Ahoy::Visit.exists?(old_visit.id), "old visit should be deleted"
    assert Ahoy::Visit.exists?(new_visit.id), "recent visit should be preserved"

    assert_equal 0, Ahoy::Event.where(name: "old_event").count, "old event should be deleted"
    assert_equal 1, Ahoy::Event.where(name: "new_event").count, "recent event should be preserved"
  end
end
