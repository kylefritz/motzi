require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Motzi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # OliveBranch converts snake_case to camelCase
    rails_routes = -> (env) { env['PATH_INFO'].match(/^\/rails/) }
    config.middleware.use OliveBranch::Middleware, inflection: "camel", exclude_params: rails_routes, exclude_response: rails_routes

    # zeitwerk makes ruby file autoloading better?
    config.autoloader = :zeitwerk

    # Rails 7 compatibility while we keep pre-7.0 load defaults during incremental upgrades.
    config.active_record.legacy_connection_handling = false
    config.time_zone = 'Eastern Time (US & Canada)'
  end
end
