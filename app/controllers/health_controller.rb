# Probe-only admin health endpoint (see UptimeSchedule). Runs the reads
# Russell's admin workflow depends on, server-side, without rendering
# anything user-facing. Token-guarded and unlinked from any UI: a bad or
# missing token (or no token configured) returns 404, so the route is
# indistinguishable from a nonexistent page to scanners.
class HealthController < ApplicationController
  skip_before_action :authenticate_user!

  STALE_QUEUE_AGE = 15.minutes

  CHECKS = {
    # The query Russell's dashboard/pickup-list workflow starts from. Raises
    # if Setting.menu_id dangles — which would break most of the admin.
    menu: -> { Menu.current.present? },
    orders: -> { Menu.current.orders.limit(1).load; true },
    error_events: -> { ErrorEvent.maximum(:id); true },
    # Probes run on the worker dyno, so a dead worker already shows up as
    # missed slots. This catches the other failure mode: a worker that still
    # heartbeats while ready jobs pile up unrun.
    queue: -> {
      oldest = SolidQueue::ReadyExecution.minimum(:created_at)
      oldest.nil? || oldest > STALE_QUEUE_AGE.ago
    }
  }.freeze

  def admin
    return head :not_found unless token_valid?

    results = run_checks
    healthy = results.values.all?("ok")
    render json: { status: healthy ? "ok" : "failing", checks: results },
           status: healthy ? :ok : :service_unavailable
  end

  private

  def token_valid?
    expected = ENV["UPTIME_PROBE_TOKEN"]
    expected.present? && ActiveSupport::SecurityUtils.secure_compare(params[:token].to_s, expected)
  end

  # Each subcheck is isolated; an exception is reported to error tracking
  # (with the subcheck name) so the diagnosis lands in /admin/error_events,
  # and surfaces in the response body for the uptime check record.
  def run_checks
    CHECKS.to_h do |name, check|
      result = begin
        check.call ? "ok" : "failing"
      rescue StandardError => e
        Rails.error.report(e, handled: true, severity: :warning, context: { health_check: name })
        "#{e.class}: #{e.message}".first(200)
      end
      [ name, result ]
    end
  end
end
