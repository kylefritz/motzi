require "test_helper"

class Admin::UptimeChecksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:kyle)
  end

  test "get index" do
    UptimeCheck.create!(target: "menu", url: "https://probe.test/menu.json", status: 200, latency_ms: 120, up: true, checked_at: 1.hour.ago)
    UptimeCheck.create!(target: "menu", url: "https://probe.test/menu.json", status: 503, latency_ms: 40, up: false, checked_at: 30.minutes.ago)

    get "/admin/uptime_checks"

    assert_response :success
    assert_match "120ms", @response.body
    assert_match "503", @response.body
  end

  test "uptime grid cell links to checks filtered by day" do
    menus(:week1).make_current!
    get "/admin/uptime_checks", params: { q: { checked_at_gteq: Date.yesterday.to_s, checked_at_lteq: Date.today.to_s } }
    assert_response :success
  end
end
