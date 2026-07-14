require "test_helper"

class UptimeCheckJobTest < ActiveJob::TestCase
  include WebMock::API

  setup do
    @original = ENV["UPTIME_PROBE_URL"]
    ENV["UPTIME_PROBE_URL"] = "https://probe.test"
  end

  teardown do
    @original ? ENV["UPTIME_PROBE_URL"] = @original : ENV.delete("UPTIME_PROBE_URL")
    WebMock.reset!
  end

  test "probes all due targets and records checks" do
    stub_request(:get, "https://probe.test/menu.json").to_return(status: 200)
    stub_request(:get, "https://probe.test/admin").to_return(status: 302)

    travel_to Time.zone.parse("2026-06-10 18:00") do # Wednesday 6pm ET: both due
      UptimeCheckJob.perform_now
    end

    assert_equal 2, UptimeCheck.count
    menu = UptimeCheck.find_by(target: "menu")
    assert menu.up
    assert_equal 200, menu.status
    assert UptimeCheck.find_by(target: "admin").up
  end

  test "probes only the targets due at the current slot" do
    stub_request(:get, "https://probe.test/menu.json").to_return(status: 200)

    travel_to Time.zone.parse("2026-06-10 18:05") do # Wed 6:05pm: menu only
      UptimeCheckJob.perform_now
    end

    assert_equal %w[menu], UptimeCheck.pluck(:target)
  end

  test "records a down check when the probe fails" do
    stub_request(:get, "https://probe.test/menu.json").to_timeout

    travel_to Time.zone.parse("2026-06-11 10:15") do # Thu: menu due, admin due
      stub_request(:get, "https://probe.test/admin").to_return(status: 302)
      UptimeCheckJob.perform_now
    end

    menu = UptimeCheck.find_by(target: "menu")
    assert_not menu.up
    assert_nil menu.status
    assert_match(/timeout/i, menu.error)
  end

  test "no-ops when no probe url is configured" do
    ENV.delete("UPTIME_PROBE_URL")

    travel_to Time.zone.parse("2026-06-10 18:00") do
      UptimeCheckJob.perform_now
    end

    assert_equal 0, UptimeCheck.count
  end
end
