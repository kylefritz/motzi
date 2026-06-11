require "test_helper"

class UptimeProbeTest < ActiveSupport::TestCase
  include WebMock::API

  setup do
    @original = ENV["UPTIME_PROBE_URL"]
    ENV.delete("UPTIME_PROBE_URL")
  end

  teardown do
    @original ? ENV["UPTIME_PROBE_URL"] = @original : ENV.delete("UPTIME_PROBE_URL")
    WebMock.reset!
  end

  test "returns nil when no probe url is configured" do
    assert_nil UptimeProbe.check
  end

  test "reports status and latency for a successful probe" do
    stub_request(:get, "https://example.test/").to_return(status: 200, body: "ok")

    result = UptimeProbe.check("https://example.test/")

    assert_equal 200, result[:status]
    assert result[:latency_ms] >= 0
    assert result[:checked_at].present?
  end

  test "reports the error when the site is unreachable" do
    stub_request(:get, "https://example.test/").to_timeout

    result = UptimeProbe.check("https://example.test/")

    assert_nil result[:status]
    assert_match(/timeout/i, result[:error])
  end

  test "uses UPTIME_PROBE_URL when set" do
    ENV["UPTIME_PROBE_URL"] = "https://probe.test/"
    stub_request(:get, "https://probe.test/").to_return(status: 200)

    assert_equal 200, UptimeProbe.check[:status]
  end
end
