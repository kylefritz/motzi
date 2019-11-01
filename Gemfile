source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.5'

#
# please keep gems sorted; include comment for why a gem is needed
#
gem 'activeadmin' # admin ui
gem 'ahoy_matey' # analytics
gem 'bcrypt', '~> 3.1.7' # for devise
gem 'bootsnap', '>= 1.4.2', require: false # Reduces boot times through caching; required in config/boot.rb
gem 'bootstrap', '~> 4.3.1' # nice style
gem 'devise' # for authentication
gem 'hashid-rails' # lookup models by hashid
gem 'image_processing', '~> 1.2' # Use Active Storage variant
gem 'jbuilder', '~> 2.7' # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'newrelic_rpm' # debugging to new relic
gem 'paper_trail' # audits
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 3.11' # web/app server
gem 'rails', '~> 6.0.0'
gem 'redcarpet' # markdown the baker's note in admin
gem 'sass-rails', '~> 5' # css
gem 'sentry-raven' # debugging to sentry.io
gem 'webpacker', '~> 4.0' # compiles javascript
gem "aws-sdk-s3", require: false # for s3/active storage
gem "olive_branch" # convert snake_case to camelCase for json
gem "rails-settings-cached" # site-wide settings


# gem 'redis', '~> 4.0' # Use Redis adapter to run Action Cable in production


group :development, :test do
  gem 'byebug' # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'dotenv-rails' # load secrets `.env` file (ask kyle for it; not checked into git)
  gem 'faker' # fake names
  gem 'json-schema' # make sure json objects have the right schema
  gem 'letter_opener_web' # nice place to preview emails
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2' # listen to changes on a file
  gem 'rcodetools' # code completion in vscode; requires ruby extension
  gem 'fastri' # helps rcodetools
  gem 'solargraph' # ruby intellisense in vscode; requires solargraph extension
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'spring'   # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'standard' # ruby formatting in vscode; requires ruby extension
  gem 'web-console', '>= 3.3.0' # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
end

group :test do
  gem 'capybara', '>= 2.15' # Adds support for Capybara system testing and selenium driver
  gem 'selenium-webdriver'
  gem 'webdrivers' # Easy installation and use of web drivers to run system tests with browsers
end
