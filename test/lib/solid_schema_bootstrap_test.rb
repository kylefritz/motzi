require "test_helper"
require "rake"
require "solid_schema_bootstrap"

# `rake release` runs solid:bootstrap on every production deploy, and
# db/queue_schema.rb creates each table with `force: :cascade`: loading it
# drops every queued, scheduled and recurring job.
class SolidSchemaBootstrapTest < ActiveSupport::TestCase
  QUEUE_SCHEMA = Rails.root.join("db/queue_schema.rb").to_s
  CABLE_SCHEMA = Rails.root.join("db/cable_schema.rb").to_s

  # Stands in for a database where only `existing` tables are there; `load`
  # creates everything the schema files ask for.
  class FakeConnection
    attr_accessor :existing

    def initialize(existing) = @existing = existing
    def data_source_exists?(table) = existing.include?(table)
  end

  def tables_in(path)
    File.read(path).scan(/create_table "([^"]+)"/).flatten
  end

  def bootstrap(connection:, loaded:, on_load: nil)
    loader = lambda do |path|
      loaded << path
      on_load&.call(path)
    end
    SolidSchemaBootstrap.new(connection:, loader:, out: StringIO.new)
  end

  test "the schema files still drop and recreate, which is why loading them needs a guard" do
    assert_operator tables_in(QUEUE_SCHEMA).size, :>=, 11
    assert_includes tables_in(QUEUE_SCHEMA), "solid_queue_jobs"
    assert_equal [ "solid_cable_messages" ], tables_in(CABLE_SCHEMA)
    assert_match(/create_table "solid_queue_jobs", force: :cascade/, File.read(QUEUE_SCHEMA))
  end

  test "loads nothing when the tables already exist (the real database)" do
    loaded = []
    out = StringIO.new
    SolidSchemaBootstrap.new(loader: ->(path) { loaded << path }, out:).call

    assert_empty loaded
    assert_includes out.string, "Solid Queue tables already present."
    assert_includes out.string, "Solid Cable tables already present."
  end

  test "rake solid:bootstrap and its solid_queue alias leave queued jobs in place" do
    Rails.application.load_tasks unless Rake::Task.task_defined?("solid:bootstrap")
    job = SolidQueue::Job.create!(queue_name: "default", class_name: "QueueDemoJob", arguments: "{}")

    %w[solid:bootstrap solid_queue:bootstrap].each do |task|
      Rake::Task["solid:bootstrap"].reenable
      Rake::Task[task].reenable
      out, = capture_io { Rake::Task[task].invoke }

      assert_includes out, "Solid Queue tables already present.", task
      assert SolidQueue::Job.exists?(job.id), "#{task} dropped solid_queue_jobs"
    end
  end

  test "the release task bootstraps through that guarded task" do
    release = File.read(Rails.root.join("lib/tasks/release.rake"))

    assert_includes release, 'Rake::Task["solid_queue:bootstrap"].invoke'
    refute_match(/queue_schema|cable_schema|load_schema/, release)
  end

  test "loads each schema when none of its tables exist" do
    loaded = []
    connection = FakeConnection.new([])
    bootstrap(connection:, loaded:, on_load: ->(path) { connection.existing += tables_in(path) }).call

    assert_equal [ QUEUE_SCHEMA, CABLE_SCHEMA ], loaded
  end

  test "loads only the schema whose tables are all missing" do
    loaded = []
    connection = FakeConnection.new(tables_in(QUEUE_SCHEMA))
    bootstrap(connection:, loaded:, on_load: ->(path) { connection.existing += tables_in(path) }).call

    assert_equal [ CABLE_SCHEMA ], loaded
  end

  # A solid_queue upgrade that adds a table to queue_schema.rb without a
  # migration leaves one table missing on production. Loading the file to
  # create it would drop the other tables and every job in them.
  test "refuses to load a schema when only some of its tables exist" do
    loaded = []
    existing = tables_in(QUEUE_SCHEMA) - [ "solid_queue_batches" ] + tables_in(CABLE_SCHEMA)

    error = assert_raises(SolidSchemaBootstrap::PartialSchemaError) do
      bootstrap(connection: FakeConnection.new(existing), loaded:).call
    end

    assert_empty loaded
    assert_includes error.message, "solid_queue_batches missing"
    assert_includes error.message, "Add a migration"
  end

  test "raises when a load leaves tables missing" do
    error = assert_raises(RuntimeError) do
      bootstrap(connection: FakeConnection.new([]), loaded: []).call
    end

    assert_match(/Solid Queue schema load incomplete; still missing: solid_queue_/, error.message)
  end
end
