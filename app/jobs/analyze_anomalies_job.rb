class AnalyzeAnomaliesJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "analyze_anomalies"

  def perform(week_id: nil, trigger: "scheduled", user_id: nil)
    week_id ||= Time.zone.now.week_id
    user = user_id ? User.find(user_id) : nil
    channel = "analysis_#{week_id}"

    broadcast(channel, status: "progress", message: "Starting analysis…")

    detector = AnomalyDetector.new(week_id) do |message|
      broadcast(channel, status: "progress", message: message)
    end

    analysis = detector.analyze(trigger: trigger, user: user)

    # TODO: could send email only for problems/warnings
    AnomalyMailer.with(analysis: analysis).anomaly_report.deliver_now

    broadcast(channel,
              status: "complete",
              first_line: analysis.result.lines.first&.strip,
              cost: "$#{'%.4f' % analysis.cost}",
              input_tokens: analysis.input_tokens,
              output_tokens: analysis.output_tokens)
  end

  private

  def broadcast(channel, payload)
    ActionCable.server.broadcast(channel, payload)
  end
end
