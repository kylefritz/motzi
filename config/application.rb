require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Motzi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # OliveBranch converts snake_case to camelCase
    config.middleware.use OliveBranch::Middleware
    config.middleware.use OliveBranch::Middleware, inflection: 'camel'

    # zeitwerk makes ruby file autoloading better?
    config.autoloader = :zeitwerk

    config.time_zone = 'Eastern Time (US & Canada)'
  end
end

# sentry/raven
Raven.configure do |config|
  config.dsn = 'https://684945c88f8c464ba5afdff9f4b07f83:7f0f0c2f9910422690fdc850a4493e59@sentry.io/1773894'
end
