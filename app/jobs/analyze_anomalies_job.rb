class AnalyzeAnomaliesJob < ApplicationJob
  queue_as :default

  def perform(week_id: nil, trigger: "scheduled", user_id: nil)
    week_id ||= Time.zone.now.week_id
    user = user_id ? User.find(user_id) : nil
    channel = "analysis_#{week_id}"

    broadcast(channel, status: "progress", message: "Starting analysis…")

    detector = AnomalyDetector.new(week_id) do |message|
      broadcast(channel, status: "progress", message: message)
    end

    analysis = detector.analyze(trigger: trigger, user: user)

    AnomalyMailer.with(analysis: analysis).anomaly_report.deliver_now

    cost = AnomalyDetector.estimate_cost(analysis.input_tokens, analysis.output_tokens)
    broadcast(channel,
      status: "complete",
      first_line: analysis.result.lines.first&.strip,
      cost: "$#{'%.4f' % cost}",
      input_tokens: analysis.input_tokens,
      output_tokens: analysis.output_tokens
    )
  end

  private

  def broadcast(channel, payload)
    ActionCable.server.broadcast(channel, payload)
  end
end
