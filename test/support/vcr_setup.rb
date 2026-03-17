require "vcr"
require "webmock"

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<ANTHROPIC_API_KEY>") { ENV["ANTHROPIC_API_KEY"] }
  config.filter_sensitive_data("<GITHUB_TOKEN>") { ENV["GITHUB_TOKEN"] }
  config.default_cassette_options = { record: ENV["VCR_RECORD"] ? :new_episodes : :none }
  config.ignore_localhost = true
  config.allow_http_connections_when_no_cassette = false
end
