class AnalyzeAnomaliesJob < ApplicationJob
  queue_as :default

  def perform
    week_id = Time.zone.now.week_id
    detector = AnomalyDetector.new(week_id)
    analysis = detector.analyze(trigger: "scheduled")

    AnomalyMailer.with(analysis: analysis).anomaly_report.deliver_now
  end
end
