Rake::Task["db:test:prepare"].enhance do
  Rake::Task["solid_queue:bootstrap"].invoke
end

namespace :solid_queue do
  desc "Create Solid Queue tables in the current database when missing"
  task bootstrap: :environment do
    schema_path = Rails.root.join("db/queue_schema.rb")
    unless File.exist?(schema_path)
      raise "Missing Solid Queue schema file at #{schema_path}"
    end

    required_tables = File.read(schema_path).scan(/create_table "([^"]+)"/).flatten
    if required_tables.empty?
      raise "Could not determine Solid Queue tables from #{schema_path}"
    end

    missing_tables = required_tables.reject do |table|
      ActiveRecord::Base.connection.data_source_exists?(table)
    end

    if missing_tables.empty?
      puts "Solid Queue tables already present."
      next
    end

    puts "Loading Solid Queue schema (missing: #{missing_tables.join(', ')})..."
    load schema_path
    still_missing = required_tables.reject do |table|
      ActiveRecord::Base.connection.data_source_exists?(table)
    end
    unless still_missing.empty?
      raise "Solid Queue schema load incomplete; still missing: #{still_missing.join(', ')}"
    end
    puts "Solid Queue schema loaded."
  end
end
