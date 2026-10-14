require "test_helper"
require "minitest/mock"

# Smoke test for the anomaly detection pipeline.
# For prompt quality testing, use `rake ai:eval` which runs against
# historical weeks with expected outcomes (test/anomaly_expectations.yml).
class AnalyzeAnomaliesJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "runs analysis and sends email" do
    menu = menus(:week1)

    travel_to_week_id(menu.week_id) do
      VCR.use_cassette("anomaly_detection_missing_orders", record: :new_episodes) do
        assert_emails 1 do
          AnalyzeAnomaliesJob.perform_now(week_id: menu.week_id, trigger: "test", user_id: users(:kyle).id)
        end

        analysis = AnomalyAnalysis.last
        assert_equal menu.week_id, analysis.week_id
        assert_equal "test", analysis.trigger
        assert_equal users(:kyle).id, analysis.user_id
        assert analysis.result.present?
      end
    end
  end

  # --- Scheduled runs only email when there's something to say (#405) ---

  # 2026-10-12 is a Monday; 2026-10-11 a Sunday (last night of ISO week 26w41).
  MONDAY_NIGHT = Time.zone.parse("2026-10-12 21:21")
  SUNDAY_NIGHT = Time.zone.parse("2026-10-11 21:21")

  # Stands in for AnomalyDetector so we don't call Claude; stores an analysis
  # with the given status the way the real detector does.
  class FakeDetector
    def initialize(status)
      @status = status
    end

    def analyze(trigger:, user: nil)
      AnomalyAnalysis.create!(week_id: Time.zone.now.week_id, result: "Status: #{@status}", trigger: trigger, user: user,
                              cost_cents: 10, input_tokens: 1000, output_tokens: 200)
    end
  end

  def with_fake_detector(status, at:, &block)
    travel_to(at) do
      AnomalyDetector.stub(:new, ->(*_args, &_progress) { FakeDetector.new(status) }, &block)
    end
  end

  def seed_previous(status, at:)
    AnomalyAnalysis.create!(week_id: at.week_id, result: "Status: #{status}", trigger: "scheduled", created_at: at)
  end

  def clear_history
    AnalysisReply.delete_all
    AnomalyAnalysis.delete_all
  end

  test "scheduled warning is emailed" do
    clear_history
    seed_previous("Warning", at: MONDAY_NIGHT - 1.day)

    with_fake_detector("Warning", at: MONDAY_NIGHT) do
      assert_emails 1 do
        assert_difference "AnomalyAnalysis.count", 1 do
          AnalyzeAnomaliesJob.perform_now
        end
      end
    end
  end

  test "scheduled unchanged healthy is stored but not emailed" do
    clear_history
    seed_previous("Healthy", at: MONDAY_NIGHT - 1.day)

    with_fake_detector("Healthy", at: MONDAY_NIGHT) do
      assert_no_emails do
        assert_difference "AnomalyAnalysis.count", 1 do
          AnalyzeAnomaliesJob.perform_now
        end
      end
    end
  end

  test "scheduled recovery to healthy is emailed" do
    clear_history
    seed_previous("Problem", at: MONDAY_NIGHT - 1.day)

    with_fake_detector("Healthy", at: MONDAY_NIGHT) do
      assert_emails 1 do
        AnalyzeAnomaliesJob.perform_now
      end
    end
    assert_includes ActionMailer::Base.deliveries.last.subject, "Healthy"
  end

  test "Sunday night sends the weekly summary even when unchanged healthy" do
    clear_history
    seed_previous("Healthy", at: SUNDAY_NIGHT - 1.day)

    with_fake_detector("Healthy", at: SUNDAY_NIGHT) do
      assert_emails 1 do
        AnalyzeAnomaliesJob.perform_now
      end
    end
    assert_includes ActionMailer::Base.deliveries.last.subject, "Weekly summary"
  end

  test "manual runs are always emailed" do
    clear_history
    seed_previous("Healthy", at: MONDAY_NIGHT - 1.day)

    with_fake_detector("Healthy", at: MONDAY_NIGHT) do
      assert_emails 1 do
        AnalyzeAnomaliesJob.perform_now(trigger: "manual", user_id: users(:kyle).id)
      end
    end
  end
end
