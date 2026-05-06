# Self-hosted error tracking. Subscribes to Rails.error so unhandled
# exceptions in controllers and Active Job get persisted to error_events.
# See app/models/error_event.rb and CLAUDE.md for the full design.

class ErrorTrackingSubscriber
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

    user = current_user_safely
    extra_context = context.except(:rack, "rack").merge(
      handled: handled,
      severity: severity,
      reporter_source: source
    ).compact

    ErrorEvent.record_server_exception(
      error,
      request: request,
      user: user,
      context: extra_context
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

  def current_user_safely
    return nil unless defined?(Current)
    Current.respond_to?(:user) ? Current.user : nil
  rescue StandardError
    nil
  end
end

Rails.error.subscribe(ErrorTrackingSubscriber.new) if Rails.error.respond_to?(:subscribe)
