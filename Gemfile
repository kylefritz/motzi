source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.4'

#
# please keep gems sorted; include comment for why a gem is needed
#
gem 'activeadmin' # admin ui
gem 'ahoy_email', '~> 1.1.1' # email analytics (v2 sadly removes open tracking)
gem 'ahoy_matey' # analytics
gem 'aws-sdk-s3', require: false # for s3/active storage
gem 'bcrypt', '~> 3.1.7' # for devise
gem 'blazer' # analytics
gem 'bootsnap', '>= 1.4.4', require: false # Reduces boot times through caching; required in config/boot.rb
gem 'bootstrap', '~> 4.3.1' # nice style
gem 'devise' # for authentication
gem 'gon' # rails variables in javascript
gem 'hashid-rails' # lookup models by hashid
gem 'image_processing', '~> 1.2' # Use Active Storage variant
gem 'jbuilder', '~> 2.7' # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'naturalsort', :require => 'natural_sort_kernel' # implements a natural, human-friendly alphanumeric sort
gem 'newrelic_rpm' # debugging to new relic
gem 'olive_branch' # convert snake_case to camelCase for json
gem 'paper_trail' # audits
gem 'pg', '>= 0.18', '< 2.0'
gem 'progress_bar'
gem 'puma', '~> 5.0' # web/app server
gem 'rails-settings-cached' # site-wide settings
gem 'rails', '~> 6.1.7.3'
gem 'redcarpet' # markdown the baker's note in admin
gem 'sass-rails', '~> 6' # css
gem 'sentry-raven' # debugging to sentry.io
gem 'sidekiq' # background work
gem 'sql_query' # load SQL queries from erb templates
gem 'stripe' # accept credit cards
gem 'webpacker', '~> 5.0' # compiles javascript


gem 'redis', '~> 4.0' # Use Redis adapter to run Action Cable in production


group :development, :test do
  gem 'byebug' # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'dotenv-rails' # load secrets `.env` file (ask kyle for it; not checked into git)
  gem 'faker' # fake names
  gem 'json-schema' # make sure json objects have the right schema
  gem 'letter_opener_web' # nice place to preview emails
end

group :development do
  gem 'listen', '~> 3.3' # listen to changes on a file
  gem 'rack-mini-profiler', '~> 2.0' # perf info like SQL time and flame graphs for each request in your browser. Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rcodetools' # code completion in vscode; requires ruby extension
  gem 'fastri' # helps rcodetools
  gem 'solargraph' # ruby intellisense in vscode; requires solargraph extension
  gem 'spring'   # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'standard' # ruby formatting in vscode; requires ruby extension
  gem 'web-console', '>= 4.1.0' # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
end

group :test do
  gem 'capybara', '>= 3.26' # Adds support for Capybara system testing and selenium driver
  gem 'stripe-ruby-mock', '3.1.0.rc3', :require => 'stripe_mock' # test Stripe code without hitting Stripe's servers
  gem 'selenium-webdriver', '>= 4.0.0.rc1'
  gem 'webdrivers' # Easy installation and use of web drivers to run system tests with browsers
end
