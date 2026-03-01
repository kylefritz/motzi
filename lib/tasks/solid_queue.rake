namespace :solid_queue do
  desc "Create Solid Queue tables in the current database when missing"
  task bootstrap: :environment do
    required_tables = %w[solid_queue_jobs solid_queue_processes]
    missing_tables = required_tables.reject do |table|
      ActiveRecord::Base.connection.data_source_exists?(table)
    end

    if missing_tables.empty?
      puts "Solid Queue tables already present."
      next
    end

    schema_path = Rails.root.join("db/queue_schema.rb")
    unless File.exist?(schema_path)
      raise "Missing Solid Queue schema file at #{schema_path}"
    end

    puts "Loading Solid Queue schema (missing: #{missing_tables.join(', ')})..."
    load schema_path
    puts "Solid Queue schema loaded."
  end
end
