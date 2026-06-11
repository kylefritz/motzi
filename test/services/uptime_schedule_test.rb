require "test_helper"

class UptimeScheduleTest < ActiveSupport::TestCase
  setup do
    @original = ENV["UPTIME_PROBE_URL"]
    ENV["UPTIME_PROBE_URL"] = "https://probe.test"
  end

  teardown do
    @original ? ENV["UPTIME_PROBE_URL"] = @original : ENV.delete("UPTIME_PROBE_URL")
  end

  # 2026-06-10 is a Wednesday; times below are ET (the app time zone).
  WED = "2026-06-10".freeze
  THU = "2026-06-11".freeze
  MON = "2026-06-08".freeze

  def et(date, hms)
    Time.zone.parse("#{date} #{hms}")
  end

  test "targets build menu and admin URLs from the probe base" do
    assert_equal %w[menu admin], UptimeSchedule.targets.map(&:name)
    assert_equal "https://probe.test/menu.json", UptimeSchedule.targets.first.url
    assert_equal "https://probe.test/admin", UptimeSchedule.targets.last.url
  end

  test "targets is empty when no probe url is configured" do
    ENV.delete("UPTIME_PROBE_URL")
    assert_empty UptimeSchedule.targets
    assert_empty UptimeSchedule.due_targets(et(WED, "18:00"))
  end

  test "menu is due every 5 minutes during the Wednesday evening surge" do
    assert UptimeSchedule.due?("menu", et(WED, "18:05"))
    assert UptimeSchedule.due?("menu", et(WED, "21:55"))
  end

  test "menu is due every 15 minutes during waking hours" do
    assert UptimeSchedule.due?("menu", et(THU, "10:15"))
    assert_not UptimeSchedule.due?("menu", et(THU, "10:05"))
  end

  test "menu is due hourly overnight" do
    assert UptimeSchedule.due?("menu", et(THU, "03:00"))
    assert_not UptimeSchedule.due?("menu", et(THU, "03:15"))
    assert UptimeSchedule.due?("menu", et(THU, "23:00"))
  end

  test "admin is due every 15 minutes during Wednesday menu posting" do
    assert UptimeSchedule.due?("admin", et(WED, "18:15"))
    assert_not UptimeSchedule.due?("admin", et(WED, "18:05"))
  end

  test "admin is due during Russell's Thu-Sat bakery hours" do
    assert UptimeSchedule.due?("admin", et(THU, "10:15"))
    assert UptimeSchedule.due?("admin", et("2026-06-13", "07:00")) # Saturday
  end

  test "admin is not probed outside Russell's windows" do
    assert_not UptimeSchedule.due?("admin", et(MON, "10:15"))
    assert_not UptimeSchedule.due?("admin", et(THU, "20:00"))
    assert_not UptimeSchedule.due?("admin", et(THU, "03:00"))
  end

  test "times round to the nearest 5-minute slot so queue latency cannot skip a cadence boundary" do
    assert UptimeSchedule.due?("menu", et(THU, "10:14:40"))
    assert UptimeSchedule.due?("menu", et(THU, "10:15:55"))
    assert_not UptimeSchedule.due?("menu", et(THU, "10:08:00"))
  end

  test "due_targets returns both targets when both cadences align" do
    assert_equal %w[menu admin], UptimeSchedule.due_targets(et(WED, "18:00")).map(&:name)
    assert_equal %w[menu], UptimeSchedule.due_targets(et(WED, "18:05")).map(&:name)
  end

  test "expected_checks counts due slots in a range" do
    # Wed 6:00pm–6:55pm: menu every 5 min = 12 slots; admin every 15 = 4 slots
    range = et(WED, "18:00")..et(WED, "18:55")
    assert_equal 12, UptimeSchedule.expected_checks("menu", range)
    assert_equal 4, UptimeSchedule.expected_checks("admin", range)
  end
end
