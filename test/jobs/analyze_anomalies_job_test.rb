require 'test_helper'

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
end
