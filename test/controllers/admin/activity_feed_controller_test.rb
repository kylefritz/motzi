require "test_helper"

class Admin::ActivityFeedControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  def setup
    menus(:week1).make_current!
    sign_in users(:kyle)
  end

  test "get index" do
    get "/admin/activity_feed"
    assert_response :success
    assert_select ".panel h3", text: "At a Glance"
    assert_select ".dense-title", text: "Code Changes"
  end

  test "get index with week_id" do
    get "/admin/activity_feed?week_id=26w01"
    assert_response :success
  end

  test "get index renders the uptime grid column and chart dataset when checks exist" do
    UptimeCheck.create!(target: "menu", url: "https://probe.test/menu.json", status: 200, latency_ms: 120, up: true, checked_at: Time.current)
    UptimeCheck.create!(target: "menu", url: "https://probe.test/menu.json", status: 503, latency_ms: 40, up: false, checked_at: 10.minutes.ago)

    get "/admin/activity_feed"

    assert_response :success
    assert_select "th", text: "Uptime"
    assert_match "Uptime %", @response.body # weekly trends chart dataset
    assert_match admin_uptime_checks_path, @response.body
  end

  test "get prompt_preview" do
    get "/admin/activity_feed/prompt_preview?week_id=26w01"
    assert_response :success
    assert_match /SYSTEM PROMPT/, @response.body
  end

  test "post analyze enqueues job" do
    assert_enqueued_with(job: AnalyzeAnomaliesJob) do
      post "/admin/activity_feed/analyze", params: { week_id: "26w01" }
    end
    assert_redirected_to "/admin/activity_feed?week_id=26w01"
  end

  test "post reply creates an admin analysis reply" do
    analysis = anomaly_analyses(:week1_analysis)

    assert_difference -> { AnalysisReply.count }, 1 do
      post "/admin/activity_feed/reply", params: { analysis_id: analysis.id, body: "Acknowledged — duplicate email finding is resolved." }
    end

    reply = AnalysisReply.last
    assert_equal "admin", reply.source
    assert_equal analysis, reply.anomaly_analysis
    assert_equal users(:kyle).email, reply.author_email
    assert_redirected_to "/admin/activity_feed?week_id=#{analysis.week_id}"
  end

  test "post reply with blank body does not create a reply" do
    analysis = anomaly_analyses(:week1_analysis)

    assert_no_difference -> { AnalysisReply.count } do
      post "/admin/activity_feed/reply", params: { analysis_id: analysis.id, body: "   " }
    end
  end

  test "analyses panel renders a quick reply form" do
    analysis = anomaly_analyses(:week1_analysis)

    get "/admin/activity_feed?week_id=#{analysis.week_id}"

    assert_response :success
    assert_select "form[action=?]", "/admin/activity_feed/reply" do
      assert_select "textarea[name=body]"
      assert_select "input[name=analysis_id][value=?]", analysis.id.to_s
    end
  end

  test "current week defaults to today and shows today marker" do
    travel_to_week_id("19w01") do
      get "/admin/activity_feed"
      assert_response :success

      # Should default to current week
      assert_select ".date-range", text: /19w01/

      # Today row should be marked
      assert_select "tr.is-today", 1
      assert_select ".today-label", text: "today"
    end
  end

  test "current week highlights in nav" do
    travel_to_week_id("19w01") do
      get "/admin/activity_feed"
      assert_response :success

      # Current week shown as span (not link) in nav
      assert_select ".activity-feed-nav span", text: "19w01"
    end
  end
end
