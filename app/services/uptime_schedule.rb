# Decides which uptime targets are due at a given moment. Cadences are
# weighted by real usage (180 days of Ahoy visits + orders, see
# docs/superpowers/specs/2026-06-11-uptime-monitoring.md):
#
#   menu  (/menu.json — anonymous, exercises Rails + Postgres + serialization)
#     Wed 5–10pm ET   every 5 min   weekly menu email lands Wed ~6pm; that
#                                   window carries ~30% of all orders
#     daily 7am–11pm  every 15 min  general member traffic
#     overnight       hourly        heartbeat only — site is near-dead
#
#   admin (/admin — 302 to sign-in proves routing/middleware/session stack)
#     Wed 4–10pm ET        every 15 min   menu gets posted Wednesday evening
#     Thu–Sat 6am–7pm ET   every 15 min   Russell's bakery-day admin hours
#     otherwise            not probed     menu probe already covers "app up"
#
# UptimeCheckJob runs every 5 minutes; times round to the nearest 5-minute
# slot so queue latency can't skip a cadence boundary.
class UptimeSchedule
  TIME_ZONE = "America/New_York"
  SLOT_MINUTES = 5
  WEDNESDAY = 3

  Target = Struct.new(:name, :url, keyword_init: true)

  def self.targets
    base = UptimeProbe.url
    return [] if base.blank?

    [
      Target.new(name: "menu", url: URI.join(base, "/menu.json").to_s),
      Target.new(name: "admin", url: admin_url(base))
    ]
  end

  # Prefers the token-guarded /health/admin endpoint, which exercises the
  # admin's real DB reads server-side (see HealthController). Falls back to
  # the public /admin redirect when no token is configured so monitoring
  # degrades instead of disappearing.
  def self.admin_url(base)
    token = ENV["UPTIME_PROBE_TOKEN"]
    return URI.join(base, "/admin").to_s if token.blank?

    URI.join(base, "/health/admin?token=#{CGI.escape(token)}").to_s
  end

  def self.due_targets(time = Time.current)
    targets.select { |target| due?(target.name, time) }
  end

  def self.due?(name, time)
    slot = slot_for(time)
    cadence = cadence_minutes(name, slot)
    return false unless cadence

    (slot.hour * 60 + slot.min) % cadence == 0
  end

  # Number of slots in range where the target was due. The activity feed
  # compares this to actual checks: missed slots mean the worker (or whole
  # app) was down, or a deploy was in flight — a signal of its own, since a
  # dead app can't record its own downtime.
  def self.expected_checks(name, range)
    slot = slot_for(range.begin)
    slot += SLOT_MINUTES.minutes if slot < range.begin

    count = 0
    while slot <= range.end
      count += 1 if due?(name, slot)
      slot += SLOT_MINUTES.minutes
    end
    count
  end

  def self.slot_for(time)
    local = time.in_time_zone(TIME_ZONE)
    seconds_into_hour = local.min * 60 + local.sec
    slot_seconds = ((seconds_into_hour + (SLOT_MINUTES * 60 / 2)) / (SLOT_MINUTES * 60)) * (SLOT_MINUTES * 60)
    local.change(min: 0, sec: 0) + slot_seconds
  end

  def self.cadence_minutes(name, slot)
    hour = slot.hour
    case name.to_s
    when "menu"
      return 5 if slot.wday == WEDNESDAY && hour.between?(17, 21)
      return 15 if hour.between?(7, 22)

      60
    when "admin"
      return 15 if slot.wday == WEDNESDAY && hour.between?(16, 21)
      return 15 if slot.wday.between?(4, 6) && hour.between?(6, 18)

      nil
    end
  end
end
