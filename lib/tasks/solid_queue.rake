require_relative "../solid_schema_bootstrap"

Rake::Task["db:test:prepare"].enhance do
  Rake::Task["solid:bootstrap"].invoke
end

namespace :solid do
  desc "Bootstrap all Solid-* schemas (Queue + Cable) on a database that has none of their tables"
  task bootstrap: :environment do
    SolidSchemaBootstrap.new.call
  end
end

# Keep backward-compatible alias
namespace :solid_queue do
  desc "Create Solid Queue tables in the current database when missing"
  task bootstrap: "solid:bootstrap"
end
