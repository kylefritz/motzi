Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.environment = Rails.env
  
  # Optional configuration
  config.traces_sample_rate = 1.0 # Adjust for performance tracing
  config.send_default_pii = true # If you want to send user data
end
