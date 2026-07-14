# Probes the site on a usage-weighted schedule. Runs every 5 minutes via
# recurring.yml; UptimeSchedule decides which targets are actually due, so
# most runs probe nothing or one URL. No-ops entirely when no probe URL is
# configured (dev/test).
class UptimeCheckJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "uptime_check"

  def perform
    UptimeSchedule.due_targets.each do |target|
      probe = UptimeProbe.check(target.url)
      next unless probe

      UptimeCheck.record!(target: target.name, probe: probe).report_outage_if_needed
    end
  end
end
