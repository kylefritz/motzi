class AnalyzeAnomaliesJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "analyze_anomalies"

  def perform(week_id: nil, trigger: "scheduled", user_id: nil)
    week_id ||= default_week_id(trigger)
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

  # The nightly run that doubles as the weekly summary email. week_id weeks
  # start on Sunday (9am), so by Sunday night "this week" is 12 hours old:
  # the summary covers the week that just ended instead.
  WEEKLY_SUMMARY_WDAY = 0 # Sunday

  private

  def weekly_summary?(trigger)
    trigger == "scheduled" && Time.zone.now.wday == WEEKLY_SUMMARY_WDAY
  end

  def default_week_id(trigger)
    weekly_summary?(trigger) ? Time.zone.now.prev_week_id : Time.zone.now.week_id
  end

  # Every analysis is stored; scheduled runs are only emailed when there is
  # something to say (#405). Manual/admin runs are always emailed.
  def deliver_report(analysis, trigger)
    reason = if trigger == "scheduled"
      analysis.email_reason(weekly_summary: weekly_summary?(trigger))
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
