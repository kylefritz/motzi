require "test_helper"

class UptimeCheckTest < ActiveSupport::TestCase
  def probe_result(status: 200, latency_ms: 120, error: nil, checked_at: Time.current)
    { url: "https://probe.test/menu.json", status: status, latency_ms: latency_ms, error: error, checked_at: checked_at }
  end

  def record_check(target: "menu", **probe_overrides)
    UptimeCheck.record!(target: target, probe: probe_result(**probe_overrides))
  end

  test "record! maps probe fields and computes up for 2xx/3xx" do
    check = record_check(status: 200)
    assert check.up
    assert_equal 200, check.status
    assert_equal 120, check.latency_ms

    assert record_check(status: 302).up
    assert_not record_check(status: 503).up
    assert_not record_check(status: nil, latency_ms: nil, error: "Timeout::Error: timed out").up
  end

  test "summary_for_period aggregates per target" do
    record_check(checked_at: 2.hours.ago, latency_ms: 100)
    record_check(checked_at: 1.hour.ago, latency_ms: 300)
    record_check(checked_at: 30.minutes.ago, status: 503, latency_ms: 50)
    record_check(target: "admin", checked_at: 1.hour.ago, status: 302)

    summary = UptimeCheck.summary_for_period(1.day.ago, Time.current)

    menu = summary["menu"]
    assert_equal 3, menu[:checks]
    assert_equal 2, menu[:up_count]
    assert_equal 66.7, menu[:pct_up]
    assert_equal 150, menu[:avg_latency_ms]
    assert_equal 300, menu[:max_latency_ms]
    assert_equal [503], menu[:failures].map(&:status)

    assert_equal 100.0, summary["admin"][:pct_up]
  end

  test "a single failure does not report an outage" do
    record_check(checked_at: 10.minutes.ago)
    check = record_check(status: 503, checked_at: 5.minutes.ago)

    assert_no_difference "ErrorEvent.count" do
      check.report_outage_if_needed
    end
  end

  test "the second consecutive failure reports one outage to error tracking" do
    record_check(checked_at: 15.minutes.ago)
    record_check(status: 503, checked_at: 10.minutes.ago)
    check = record_check(status: nil, latency_ms: nil, error: "Errno::ECONNREFUSED: connection refused", checked_at: 5.minutes.ago)

    assert_difference "ErrorEvent.count", 1 do
      check.report_outage_if_needed
    end

    event = ErrorEvent.order(:id).last
    assert_equal "UptimeCheck::OutageError", event.error_class
    assert_match(/menu down 2 consecutive checks/, event.message)
    assert_match(/connection refused/, event.message)
  end

  test "an ongoing outage is not re-reported on later failures" do
    record_check(status: 503, checked_at: 15.minutes.ago)
    record_check(status: 503, checked_at: 10.minutes.ago)
    check = record_check(status: 503, checked_at: 5.minutes.ago)

    assert_no_difference "ErrorEvent.count" do
      check.report_outage_if_needed
    end
  end

  test "a new outage after recovery reports again" do
    record_check(status: 503, checked_at: 40.minutes.ago)
    record_check(status: 503, checked_at: 35.minutes.ago)
    record_check(status: 200, checked_at: 30.minutes.ago)
    record_check(status: 503, checked_at: 10.minutes.ago)
    check = record_check(status: 503, checked_at: 5.minutes.ago)

    assert_difference "ErrorEvent.count", 1 do
      check.report_outage_if_needed
    end
  end

  test "successful checks never report" do
    record_check(status: 503, checked_at: 10.minutes.ago)
    check = record_check(status: 200, checked_at: 5.minutes.ago)

    assert_no_difference "ErrorEvent.count" do
      check.report_outage_if_needed
    end
  end

  test "outage streaks are tracked per target" do
    record_check(target: "menu", status: 503, checked_at: 10.minutes.ago)
    check = record_check(target: "admin", status: 503, checked_at: 5.minutes.ago)

    assert_no_difference "ErrorEvent.count" do
      check.report_outage_if_needed
    end
  end
end
