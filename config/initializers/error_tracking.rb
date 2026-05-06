# Self-hosted error tracking. Subscribes to Rails.error so unhandled
# exceptions in controllers and Active Job get persisted to error_events.
# See app/models/error_event.rb and CLAUDE.md for the full design.

class ErrorTrackingSubscriber
  JOB_SOURCE_PATTERNS = [/active_job/i, /\bjob\b/i, /solid_queue/i].freeze

  def report(error, handled:, severity:, context:, source: nil)
    return if severity == :info
    return if ignored.include?(error.class.name)

    rack_env = context[:rack] || context["rack"]
    request =
      if rack_env.is_a?(Hash)
        ActionDispatch::Request.new(rack_env)
      elsif rack_env.respond_to?(:request_id)
        rack_env
      end

    extra_context = context.except(:rack, "rack").merge(
      handled: handled,
      severity: severity,
      reporter_source: source
    ).compact

    ErrorEvent.record_server_exception(
      error,
      request: request,
      user: Current.user,
      context: extra_context,
      source: classify_source(source, context, request)
    )
  rescue StandardError => e
    Rails.logger.warn("[ErrorTracking] failed to record exception: #{e.class}: #{e.message}")
  end

  private

  # Looked up lazily — the ErrorEvent constant isn't available when the
  # initializer runs in some boot paths (autoloader not yet primed).
  def ignored
    @ignored ||= ErrorEvent::IGNORED_SERVER_EXCEPTIONS.to_set
  end

  def classify_source(reporter_source, context, _request)
    src = reporter_source.to_s
    return "job" if JOB_SOURCE_PATTERNS.any? { |p| src.match?(p) }
    if context.is_a?(Hash) &&
       (context.key?(:job) || context.key?("job") ||
        context.key?(:job_class) || context.key?("job_class") ||
        context.key?(:job_id) || context.key?("job_id"))
      return "job"
    end
    "server"
  end

end

Rails.error.subscribe(ErrorTrackingSubscriber.new) if Rails.error.respond_to?(:subscribe)
