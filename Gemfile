source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.10'

#
# please keep gems sorted; include comment for why a gem is needed
#
gem 'activeadmin', '~> 3.4' # admin ui
gem 'ahoy_email', '~> 1.1.1' # email analytics (v2 sadly removes open tracking)
gem 'ahoy_matey' # analytics
gem 'anthropic' # Claude API for anomaly detection
gem 'aws-sdk-s3', require: false # for s3/active storage
gem 'bcrypt', '~> 3.1.7' # for devise
gem 'blazer' # analytics
gem 'bootsnap', '>= 1.4.4', require: false # Reduces boot times through caching; required in config/boot.rb
gem 'bootstrap', '~> 4.3.1' # nice style
gem 'concurrent-ruby', '1.3.4' # pinned for compatibility
gem 'devise' # for authentication
gem 'drb' # stdlib gem (Ruby 3.4 deprecation warning)
gem 'gon' # rails variables in javascript
gem 'hashid-rails' # lookup models by hashid
gem 'heroku-api-postgres' # Heroku Postgres API for automated backups
gem 'image_processing', '~> 1.2' # Use Active Storage variant
gem 'jaro_winkler', '~> 1.5.5' # pinned for compatibility
gem 'jbuilder', '~> 2.7' # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jsbundling-rails' # build JS via rails asset pipeline hooks
gem 'mission_control-jobs' # job UI for ActiveJob backends
gem 'mjml-rails' # responsive email templates with MJML
gem 'mrml' # Rust MJML binary (no Node dependency)
gem 'mutex_m' # stdlib gem (Ruby 3.4 deprecation warning)
gem 'naturalsort', :require => 'natural_sort_kernel' # implements a natural, human-friendly alphanumeric sort
gem 'newrelic_rpm' # debugging to new relic
gem 'octokit', '~> 10.0' # GitHub API for git commit history in anomaly detection
gem 'olive_branch' # convert snake_case to camelCase for json
gem 'paper_trail' # audits
gem 'pg', '>= 0.18', '< 2.0'
gem 'progress_bar'
gem 'puma', '~> 7.0' # web/app server
gem 'rails', '~> 7.2.0'
gem 'rails-settings-cached' # site-wide settings
gem 'redcarpet' # markdown the baker's note in admin
gem 'sass-rails', '~> 6' # css
gem 'sentry-rails' # Rails integration for Sentry
gem 'sentry-ruby' # New Sentry SDK
gem 'solid_cable', '~> 3.0' # database-backed ActionCable adapter (no Redis)
gem 'solid_cache' # Postgres-backed Rails cache store (no Redis/Memcached)
gem 'solid_queue' # database-backed ActiveJob backend (Rails 7.2+)
gem 'sql_query' # load SQL queries from erb templates
gem 'stripe' # accept credit cards

group :development, :test do
  gem 'byebug' # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'dotenv-rails' # load secrets `.env` file (ask kyle for it; not checked into git)
  gem 'faker' # fake names
  gem 'json-schema' # make sure json objects have the right schema
  gem 'letter_opener_web' # nice place to preview emails
  gem 'minitest' # test framework; keep unpinned so Rails can track supported versions
end

group :development do
  gem 'foreman' # run Procfile.dev (Rails + bun watch) locally
  gem 'listen', '~> 3.3' # listen to changes on a file
  gem 'rack-mini-profiler', '~> 4.0' # request profiling UI compatible with modern Rack/Rails
  gem 'rcodetools' # code completion in vscode; requires ruby extension
  gem 'fastri' # helps rcodetools
  gem 'solargraph' # ruby intellisense in vscode; requires solargraph extension
  gem 'spring'   # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'rubocop-rails-omakase' # Rails 8 default rubocop config
  gem 'web-console', '>= 4.1.0' # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
end

group :test do
  gem 'capybara', '>= 3.26' # Adds support for Capybara system testing and selenium driver
  gem 'selenium-webdriver', '>= 4.0.0.rc1'
  gem 'stripe-ruby-mock', '3.1.0.rc3', :require => 'stripe_mock' # test Stripe code without hitting Stripe's servers
  gem 'vcr' # record and replay HTTP interactions for tests
  gem 'webdrivers' # Easy installation and use of web drivers to run system tests with browsers
  gem 'webmock' # stub HTTP requests in tests
end
