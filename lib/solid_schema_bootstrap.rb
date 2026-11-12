# Creates the Solid Queue and Solid Cable tables on a database that has none of
# them (`rake solid:bootstrap`, which the Heroku release task runs on every
# deploy).
#
# db/queue_schema.rb and db/cable_schema.rb create every table with
# `force: :cascade`, so loading one drops whatever is there first: on
# production that is every queued, scheduled and recurring job. So a schema
# file is loaded only when none of its tables exist. All present is a no-op.
# Some present and some missing (a gem upgrade that added a table to the schema
# file without a migration) raises instead of loading, which fails the release
# and leaves the tables alone.
class SolidSchemaBootstrap
  SCHEMAS = {
    "Solid Queue" => "db/queue_schema.rb",
    "Solid Cable" => "db/cable_schema.rb"
  }.freeze

  class PartialSchemaError < StandardError; end

  def initialize(connection: ActiveRecord::Base.connection, root: Rails.root,
                 loader: ->(path) { load path }, out: $stdout)
    @connection = connection
    @root = Pathname(root)
    @loader = loader
    @out = out
  end

  def call
    SCHEMAS.each { |name, path| bootstrap(name, path) }
  end

  private

  def bootstrap(name, path)
    schema_path = @root.join(path)
    return unless File.exist?(schema_path)

    required = File.read(schema_path).scan(/create_table "([^"]+)"/).flatten
    return if required.empty?

    missing = missing_tables(required)
    if missing.empty?
      @out.puts "#{name} tables already present."
      return
    end

    present = required - missing
    if present.any?
      raise PartialSchemaError,
        "#{name}: #{missing.join(', ')} missing but #{present.size} other tables exist. " \
        "Loading #{path} would drop and recreate them (force: :cascade) and delete their rows. " \
        "Add a migration that creates the missing tables instead."
    end

    @out.puts "Loading #{name} schema (missing: #{missing.join(', ')})..."
    @loader.call(schema_path.to_s)
    still_missing = missing_tables(required)
    unless still_missing.empty?
      raise "#{name} schema load incomplete; still missing: #{still_missing.join(', ')}"
    end
    @out.puts "#{name} schema loaded."
  end

  def missing_tables(tables)
    tables.reject { |table| @connection.data_source_exists?(table) }
  end
end
