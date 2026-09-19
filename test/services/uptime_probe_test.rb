require "test_helper"
require "minitest/mock"

class UptimeProbeTest < ActiveSupport::TestCase
  include WebMock::API

  setup do
    @original_env = ENV.to_h.slice("UPTIME_PROBE_URL", "CANONICAL_HOST", "HEROKU_APP_NAME")
    @original_env.each_key { |key| ENV.delete(key) }
  end

  teardown do
    %w[UPTIME_PROBE_URL CANONICAL_HOST HEROKU_APP_NAME].each { |key| ENV.delete(key) }
    @original_env.each { |key, value| ENV[key] = value }
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

  test "preserves the query string of a configured probe url" do
    stub_request(:get, "https://example.test/health?token=secret").to_return(status: 200)

    result = UptimeProbe.check("https://example.test/health?token=secret")

    assert_equal 200, result[:status]
    assert_requested :get, "https://example.test/health?token=secret"
  end

  test "uses UPTIME_PROBE_URL when set" do
    ENV["UPTIME_PROBE_URL"] = "https://probe.test/"
    stub_request(:get, "https://probe.test/").to_return(status: 200)

    assert_equal 200, UptimeProbe.check[:status]
  end

  test "production probes the canonical host once CANONICAL_HOST is set" do
    ENV["HEROKU_APP_NAME"] = "motzibread"
    ENV["CANONICAL_HOST"] = "motzibread.com"

    Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new("production")) do
      assert_equal "https://motzibread.com", UptimeProbe.url
    end
  end

  test "production probes the heroku host before the cutover" do
    ENV["HEROKU_APP_NAME"] = "motzibread"

    Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new("production")) do
      assert_equal "https://motzibread.herokuapp.com", UptimeProbe.url
    end
  end

  test "UPTIME_PROBE_URL overrides the canonical host" do
    ENV["CANONICAL_HOST"] = "motzibread.com"
    ENV["UPTIME_PROBE_URL"] = "https://probe.test/"

    assert_equal "https://probe.test/", UptimeProbe.url
  end
end
