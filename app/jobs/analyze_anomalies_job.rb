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
    deliver_report(analysis, trigger)

    broadcast(channel,
              status: "complete",
              first_line: analysis.result.lines.first&.strip,
              cost: "$#{'%.4f' % analysis.cost}",
              input_tokens: analysis.input_tokens,
              output_tokens: analysis.output_tokens)
  end

  # The nightly run that doubles as the weekly summary email. Sunday night is
  # the last scheduled run of the ISO week (week_id), so it covers the whole
  # bakery week before the next menu goes out.
  WEEKLY_SUMMARY_WDAY = 0 # Sunday

  private

  # Every analysis is stored; scheduled runs are only emailed when there is
  # something to say (#405). Manual/admin runs are always emailed.
  def deliver_report(analysis, trigger)
    reason = if trigger == "scheduled"
      analysis.email_reason(weekly_summary: Time.zone.now.wday == WEEKLY_SUMMARY_WDAY)
    else
      :requested
    end

    if reason
      AnomalyMailer.with(analysis: analysis, reason: reason).anomaly_report.deliver_now
    else
      Rails.logger.info "AnalyzeAnomaliesJob: analysis #{analysis.id} unchanged (#{analysis.overall_status}); not emailing"
    end
  end

  def broadcast(channel, payload)
    ActionCable.server.broadcast(channel, payload)
  end
end
