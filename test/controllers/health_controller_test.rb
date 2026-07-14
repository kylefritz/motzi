require "test_helper"
require "minitest/mock"

class HealthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original = ENV["UPTIME_PROBE_TOKEN"]
    ENV["UPTIME_PROBE_TOKEN"] = "probe-secret"
    menus(:week1).make_current!
  end

  teardown do
    @original ? ENV["UPTIME_PROBE_TOKEN"] = @original : ENV.delete("UPTIME_PROBE_TOKEN")
  end

  test "404 without a token, with a wrong token, and when no token is configured" do
    get "/health/admin"
    assert_response :not_found

    get "/health/admin", params: { token: "wrong" }
    assert_response :not_found

    ENV.delete("UPTIME_PROBE_TOKEN")
    get "/health/admin", params: { token: "probe-secret" }
    assert_response :not_found
  end

  test "200 with all subchecks ok when the admin's reads work" do
    get "/health/admin", params: { token: "probe-secret" }

    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal "ok", body["status"]
    # olive_branch camelizes response keys app-wide
    assert_equal %w[menu orders errorEvents queue], body["checks"].keys
    assert body["checks"].values.all?("ok"), body["checks"].inspect
  end

  test "503 with the failing subcheck named when a dependency breaks" do
    Setting.menu_id = 999_999 # dangling — Menu.current raises

    # RecordNotFound is in ErrorEvent::IGNORED_SERVER_EXCEPTIONS, so no
    # ErrorEvent here — the diagnosis travels in the response body, and the
    # 503 itself records the uptime check as down (outage flow handles it).
    assert_no_difference "ErrorEvent.count" do
      get "/health/admin", params: { token: "probe-secret" }
    end

    assert_response :service_unavailable
    body = JSON.parse(@response.body)
    assert_equal "failing", body["status"]
    assert_match(/RecordNotFound/, body["checks"]["menu"])
    assert_equal "ok", body["checks"]["errorEvents"]
  end

  test "503 when ready jobs have been sitting unrun past the stale threshold" do
    SolidQueue::ReadyExecution.stub :minimum, 20.minutes.ago do
      get "/health/admin", params: { token: "probe-secret" }
    end

    assert_response :service_unavailable
    assert_equal "failing", JSON.parse(@response.body)["checks"]["queue"]
  end
end
