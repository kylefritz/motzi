require "test_helper"

class AnomalyDetectorIntegrationTest < ActiveSupport::TestCase
  include WebMock::API

  test "build_user_message includes uptime probe result when configured" do
    ENV["UPTIME_PROBE_URL"] = "https://probe.test/"
    stub_request(:get, "https://probe.test/").to_return(status: 200, body: "ok")

    message = AnomalyDetector.new("19w01").build_user_message

    assert_match(/Uptime Probe/, message)
    assert_match(/responded 200 in \d+ms/, message)
  ensure
    ENV.delete("UPTIME_PROBE_URL")
    WebMock.reset!
  end

  test "build_user_message omits uptime probe section when not configured" do
    message = AnomalyDetector.new("19w01").build_user_message

    assert_no_match(/Uptime Probe/, message)
  end

  test "build_user_message with analyses_before excludes analyses created after the cutoff" do
    prior = anomaly_analyses(:week1_analysis)
    AnomalyAnalysis.create!(
      week_id: "19w02", trigger: "scheduled",
      result: "Status: ✅ Healthy\nFUTURE LEAK MARKER",
      created_at: prior.created_at + 2.weeks
    )

    message = AnomalyDetector.new("19w01", analyses_before: prior.created_at + 1.day).build_user_message

    assert_includes message, "Everything looks fine this week.",
      "analyses before the cutoff should still be included"
    assert_no_match(/FUTURE LEAK MARKER/, message)
  end

  test "detects anomaly when orders are missing" do
    menu = menus(:week1)
    travel_to_week_id(menu.week_id) do
      VCR.use_cassette("anomaly_detection_missing_orders", record: :new_episodes) do
        detector = AnomalyDetector.new(menu.week_id)
        analysis = detector.analyze(trigger: "test")

        assert analysis.persisted?
        assert analysis.result.present?
        assert_equal menu.week_id, analysis.week_id
        assert_equal "test", analysis.trigger
        assert_equal AnomalyDetector.model, analysis.model_used
      end
    end
  end

  test "builds user message with current and comparison weeks" do
    menu = menus(:week1)
    travel_to_week_id(menu.week_id) do
      detector = AnomalyDetector.new(menu.week_id, comparison_weeks: 2)
      message = detector.send(:build_user_message)

      assert_includes message, "Current Week (analyze this week for anomalies):"
      assert_includes message, "Comparison Week:"
    end
  end

  test "system prompt asks claude to consider relevant code changes" do
    detector = AnomalyDetector.new("19w01")
    prompt = detector.system_prompt

    assert_includes prompt, "Whether recent code changes could plausibly explain the behavior you see this week"
    assert_includes prompt, "Treat code changes as supporting evidence, not proof"
  end

  test "build_user_message includes replies alongside prior analyses" do
    prior_week_id = "19w01"  # matches week1_analysis fixture
    prior = anomaly_analyses(:week1_analysis)
    prior.replies.create!(
      author_email: "kyle@example.com",
      author_name: "Kyle Fritz",
      body: "R14 is expected — please stop flagging it.",
      source: :email
    )

    detector = AnomalyDetector.new(prior_week_id)
    message = detector.build_user_message

    assert_includes message, "R14 is expected",
      "expected reply body to appear in the prompt"
    assert_includes message, "Operator replies",
      "expected an Operator replies heading"
  end
end
