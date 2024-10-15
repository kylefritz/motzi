Sidekiq.configure_server do |config|
  puts "Configuring Sidekiq server with Redis URL: #{ENV["REDIS_URL"]}"
  config.redis = {
    url: ENV["REDIS_URL"],
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end

Sidekiq.configure_client do |config|
  puts "Configuring Sidekiq client with Redis URL: #{ENV["REDIS_URL"]}"
  config.redis = {
      url: ENV["REDIS_URL"],
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end
