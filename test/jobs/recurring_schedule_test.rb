require "test_helper"
require "fugit"

class RecurringScheduleTest < ActiveSupport::TestCase
  setup do
    @config = YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true)
    @production = @config.fetch("production")
  end

  test "recurring.yml is valid YAML with a production key" do
    assert @config.is_a?(Hash)
    assert @production.is_a?(Hash)
    assert @production.size > 0
  end

  test "all expected jobs are present" do
    expected_jobs = %w[
      clear_solid_queue_finished_jobs
      send_day_of_reminder
      send_havent_ordered_reminder
      trim_analytics
      analyze_anomalies
      capture_dyno_metrics
      capture_db_backup
    ]

    expected_jobs.each do |job|
      assert @production.key?(job), "Missing expected job: #{job}"
    end
  end

  test "all schedules parse as Fugit::Cron" do
    @production.each do |name, config|
      schedule = config["schedule"]
      assert schedule.present?, "#{name} is missing a schedule"

      parsed = Fugit.parse(schedule, multi: :fail)
      assert_instance_of Fugit::Cron, parsed,
        "#{name} schedule '#{schedule}' did not parse as Fugit::Cron (got #{parsed.class}). " \
        "Solid Queue will reject this and the worker will crash."
    end
  end

  test "all jobs with a class reference a valid job class" do
    @production.each do |name, config|
      next unless config["class"]
      klass = config["class"].safe_constantize
      assert klass, "#{name} references unknown class: #{config['class']}"
      assert klass < ApplicationJob, "#{name} class #{config['class']} is not an ApplicationJob"
    end
  end

  test "no two jobs share the same minute to avoid resource contention" do
    minutes_by_job = {}

    @production.each do |name, config|
      parsed = Fugit::Cron.parse(config["schedule"]) || Fugit.parse(config["schedule"], multi: :fail)
      next unless parsed.is_a?(Fugit::Cron)

      mins = parsed.minutes
      next unless mins # e.g. weekly jobs with no specific minute constraint

      minutes_by_job[name] = mins.map(&:to_s)
    end

    # Check for collisions among frequently-running jobs (hourly or more)
    frequent_jobs = minutes_by_job.select do |name, _|
      schedule = @production[name]["schedule"]
      schedule.include?("every hour") || schedule.match?(/^[\d,]+\s/)
    end

    seen_minutes = {}
    frequent_jobs.each do |name, mins|
      mins.each do |min|
        if seen_minutes[min]
          flunk "Minute :#{min} collision between '#{seen_minutes[min]}' and '#{name}'"
        end
        seen_minutes[min] = name
      end
    end
    assert seen_minutes.any?, "Expected at least one frequent job with a parsed minute"
  end
end
