class ErrorEventsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create]

  RATE_LIMIT = 30
  RATE_WINDOW = 60 # seconds

  def create
    if rate_limited?
      head :too_many_requests
      return
    end

    payload = params.permit(:error_class, :message, :stack, :url, context: {}).to_h

    ErrorEvent.record_browser_exception(
      error_class: payload["error_class"].presence || "Error",
      message: payload["message"].to_s,
      stack: payload["stack"].to_s,
      url: payload["url"].to_s,
      context: payload["context"] || {},
      user: current_user,
      request: request
    )

    head :no_content
  rescue ActiveRecord::RecordInvalid, ActiveRecord::ActiveRecordError
    head :unprocessable_entity
  rescue StandardError => e
    Rails.logger.warn("[ErrorEventsController] ingest failed: #{e.class}: #{e.message}")
    head :unprocessable_entity
  end

  private

  def rate_limited?
    key = "error_events:ingest:#{current_user&.id || request.remote_ip}"
    count = Rails.cache.increment(key, 1, expires_in: RATE_WINDOW)
    if count.nil?
      Rails.cache.write(key, 1, expires_in: RATE_WINDOW)
      count = 1
    end
    count.to_i > RATE_LIMIT
  end
end
