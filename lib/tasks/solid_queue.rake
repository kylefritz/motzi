Rake::Task["db:test:prepare"].enhance do
  Rake::Task["solid:bootstrap"].invoke
end

namespace :solid do
  desc "Bootstrap all Solid-* schemas (Queue + Cable)"
  task bootstrap: :environment do
    {
      "Solid Queue" => "db/queue_schema.rb",
      "Solid Cable" => "db/cable_schema.rb"
    }.each do |name, path|
      schema_path = Rails.root.join(path)
      next unless File.exist?(schema_path)

      required_tables = File.read(schema_path).scan(/create_table "([^"]+)"/).flatten
      next if required_tables.empty?

      missing_tables = required_tables.reject do |table|
        ActiveRecord::Base.connection.data_source_exists?(table)
      end

      if missing_tables.empty?
        puts "#{name} tables already present."
        next
      end

      puts "Loading #{name} schema (missing: #{missing_tables.join(', ')})..."
      load schema_path
      still_missing = required_tables.reject do |table|
        ActiveRecord::Base.connection.data_source_exists?(table)
      end
      unless still_missing.empty?
        raise "#{name} schema load incomplete; still missing: #{still_missing.join(', ')}"
      end
      puts "#{name} schema loaded."
    end
  end
end

# Keep backward-compatible alias
namespace :solid_queue do
  desc "Create Solid Queue tables in the current database when missing"
  task bootstrap: "solid:bootstrap"
end
