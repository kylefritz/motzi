require "test_helper"
require "minitest/mock"

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
      # No record: option, so this inherits :none (test/support/vcr_setup.rb). With
      # :new_episodes a request missing from the cassette called Anthropic for real.
      VCR.use_cassette("anomaly_detection_missing_orders") do
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

  test "a stored setting that names a retired model runs its successor" do
    Setting.anomaly_model = "claude-sonnet-4-6"
    assert_equal "claude-sonnet-5-5", AnomalyDetector.model
    assert_equal "Sonnet 5.5", AnomalyDetector.model_label

    Setting.anomaly_model = "claude-haiku-4-5"
    assert_equal "claude-haiku-5-5", AnomalyDetector.model
  ensure
    Setting.anomaly_model = nil
  end

  test "old analyses keep their model's label and price" do
    assert_equal "Sonnet 4.6", AnomalyDetector.label_for("claude-sonnet-4-6")
    assert_equal "some-future-model", AnomalyDetector.label_for("some-future-model")
    # 1M in + 1M out at Sonnet 4.6's $3 / $15
    assert_in_delta 18.0, AnomalyDetector.estimate_cost(1_000_000, 1_000_000, "claude-sonnet-4-6")
  end

  test "estimate_cost uses current prices, and Haiku's higher rate past 100K prompt tokens" do
    assert_in_delta 0.12, AnomalyDetector.estimate_cost(50_000, 2_000, "claude-sonnet-5-5")
    assert_in_delta 0.006, AnomalyDetector.estimate_cost(50_000, 2_000, "claude-haiku-5-5")
    assert_in_delta 0.08, AnomalyDetector.estimate_cost(150_000, 2_000, "claude-haiku-5-5")
  end

  test "a refusal raises instead of saving an empty report" do
    refusal = Struct.new(:content, :stop_reason, :model, :usage).new([], :refusal, "claude-sonnet-5-5", nil)
    messages = Object.new
    messages.define_singleton_method(:create) { |**_params| refusal }
    client = Struct.new(:messages).new(messages)

    Anthropic::Client.stub(:new, client) do
      error = assert_raises(AnomalyDetector::NoReport) { AnomalyDetector.new("19w01").run_analysis }
      assert_match(/refusal/, error.message)
    end
    assert_no_difference -> { AnomalyAnalysis.count } do
      Anthropic::Client.stub(:new, client) do
        assert_raises(AnomalyDetector::NoReport) { AnomalyDetector.new("19w01").analyze(trigger: "test") }
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
