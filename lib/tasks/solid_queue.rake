Rake::Task["db:test:prepare"].enhance do
  Rake::Task["solid:bootstrap"].invoke
end

namespace :solid do
  desc "Bootstrap all Solid-* schemas (Queue + Cable) on a database that has none of their tables"
  task bootstrap: :environment do
    # Required here, not at the top: `bin/rails test` loads the rake tasks
    # before SimpleCov starts, which would hide the file from coverage.
    require_relative "../solid_schema_bootstrap"
    SolidSchemaBootstrap.new.call
  end
end

# Keep backward-compatible alias
namespace :solid_queue do
  desc "Create Solid Queue tables in the current database when missing"
  task bootstrap: "solid:bootstrap"
end
