# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

# vite_rails runs `bun install` before its assets:precompile build. JS deps are
# already installed by then (Heroku's bun buildpack, CI, bin/setup), so skip it.
ENV["VITE_RUBY_SKIP_ASSETS_PRECOMPILE_INSTALL"] ||= "true"

require_relative 'config/application'

Rails.application.load_tasks
