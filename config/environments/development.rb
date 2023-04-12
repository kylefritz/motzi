require_relative "../../app/models/shop_config"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # uncomment to test production queue settings
  #
  # config.active_job.queue_adapter = ShopConfig.shop.queue_adapter.to_sym
  # config.action_mailer.deliver_later_queue_name = "mailers"        # defaults to "mailers"
  # config.active_storage.queues.analysis         = "active_storage" # defaults to "active_storage_analysis"
  # config.active_storage.queues.purge            = "active_storage" # defaults to "active_storage_purge"
  # config.active_storage.queues.mirror           = "active_storage" # defaults to "active_storage_mirror"
  # config.active_storage.queues.purge            = "active_storage" # alternatively, put purge jobs in the `low` queue

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # save sent emails to letter opener
  config.action_mailer.delivery_method = :letter_opener_web

  # point links to localhost
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # https://github.com/sass/sassc-rails/issues/102
  # config.sass.inline_source_maps = true
  # config.assets.cache_store = :null_store  # Disables the Asset cache
  config.sass.cache = false  # Disable the SASS compiler cache, _shop.scss.erb stale in cache

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
