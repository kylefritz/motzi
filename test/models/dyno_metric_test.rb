require "test_helper"

class DynoMetricTest < ActiveSupport::TestCase
  test "summary_for_period returns avg and max grouped by dyno" do
    base = 2.hours.ago
    DynoMetric.create!(recorded_at: base, dyno: "web.1", memory_total: 300, memory_rss: 280, memory_swap: 0, memory_quota: 512, r14_count: 0)
    DynoMetric.create!(recorded_at: base + 1.hour, dyno: "web.1", memory_total: 500, memory_rss: 450, memory_swap: 20, memory_quota: 512, r14_count: 2)
    DynoMetric.create!(recorded_at: base, dyno: "worker.1", memory_total: 200, memory_rss: 180, memory_swap: 0, memory_quota: 512, r14_count: 0)

    result = DynoMetric.summary_for_period(base - 1.minute, base + 2.hours)

    web = result["web.1"]
    assert_equal 400, web[:avg_memory_total]
    assert_equal 500, web[:max_memory_total]
    assert_equal 512, web[:memory_quota]
    assert_equal 2, web[:total_r14]

    worker = result["worker.1"]
    assert_equal 200, worker[:avg_memory_total]
    assert_equal 0, worker[:total_r14]
  end

  test "summary_for_period returns empty hash when no records" do
    result = DynoMetric.summary_for_period(1.day.ago, Time.current)
    assert_equal({}, result)
  end
end
