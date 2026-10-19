require "test_helper"
require "webmock/minitest"

class LogDrainTest < ActiveSupport::TestCase
  URL = "https://logs.example.test/motzi"

  setup do
    @env = ENV.to_h.slice("LOG_DRAIN_URL", "LOG_DRAIN_READ_TOKEN")
    ENV["LOG_DRAIN_URL"] = URL
    ENV["LOG_DRAIN_READ_TOKEN"] = "read-token"
  end

  teardown do
    %w[LOG_DRAIN_URL LOG_DRAIN_READ_TOKEN].each { |k| @env.key?(k) ? ENV[k] = @env[k] : ENV.delete(k) }
  end

  test "configured? needs both the URL and the read token" do
    assert LogDrain.configured?
    ENV.delete("LOG_DRAIN_READ_TOKEN")
    assert_not LogDrain.configured?
  end

  test "fetch sends the window and token, and follows X-Next-Cursor" do
    since = Time.utc(2026, 10, 19, 20, 0, 0)
    first = stub_request(:get, "#{URL}/logs")
      .with(query: { since: "2026-10-19T20:00:00.000Z", q: "status=500" }, headers: { "Authorization" => "Bearer read-token" })
      .to_return(status: 200, body: "line 1\n", headers: { "X-Next-Cursor" => "motzi/2026/10/19/20/a.log" })
    second = stub_request(:get, "#{URL}/logs")
      .with(query: { since: "2026-10-19T20:00:00.000Z", q: "status=500", cursor: "motzi/2026/10/19/20/a.log" })
      .to_return(status: 200, body: "line 2\n")

    assert_equal "line 1\nline 2\n", LogDrain.fetch(since: since, query: "status=500")
    assert_requested first
    assert_requested second
  end

  test "fetch raises on an error response" do
    stub_request(:get, "#{URL}/logs").with(query: hash_including({})).to_return(status: 401)

    error = assert_raises(RuntimeError) { LogDrain.fetch(since: 30.minutes.ago) }
    assert_match "401", error.message
  end
end
