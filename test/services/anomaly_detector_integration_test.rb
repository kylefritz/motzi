require "test_helper"

class AnomalyDetectorIntegrationTest < ActiveSupport::TestCase
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
        assert_equal "claude-opus-4-6", analysis.model_used
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
end
