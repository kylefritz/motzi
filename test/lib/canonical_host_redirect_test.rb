require "test_helper"
require "canonical_host_redirect"

class CanonicalHostRedirectTest < ActiveSupport::TestCase
  def middleware
    app = ->(_env) { [ 200, {}, [ "ok" ] ] }
    CanonicalHostRedirect.new(app, "motzibread.com")
  end

  def call(host:, path: "/", query: nil)
    env = Rack::MockRequest.env_for("https://#{host}#{path}#{query ? "?#{query}" : ""}")
    middleware.call(env)
  end

  test "301s other hosts to the canonical host, preserving path and query" do
    status, headers, = call(host: "motzibread.herokuapp.com", path: "/subscribe", query: "a=1")
    assert_equal 301, status
    assert_equal "https://motzibread.com/subscribe?a=1", headers["Location"]
  end

  test "passes through requests already on the canonical host" do
    status, = call(host: "motzibread.com", path: "/menu")
    assert_equal 200, status
  end

  test "exempts health checks so probes reach the dyno directly" do
    status, = call(host: "motzibread.herokuapp.com", path: "/health/admin")
    assert_equal 200, status
  end
end
