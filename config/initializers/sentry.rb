Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.environment = Rails.env
  config.traces_sample_rate = 1.0
  config.send_default_pii = false
end
