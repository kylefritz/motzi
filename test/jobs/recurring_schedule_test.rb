require "test_helper"

class RecurringScheduleTest < ActiveSupport::TestCase
  setup do
    @config = YAML.load_file(Rails.root.join("config/recurring.yml"))
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

  test "all jobs have a schedule" do
    @production.each do |name, config|
      assert config["schedule"].present?, "#{name} is missing a schedule"
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
    # Extract minutes from schedules for hourly+ jobs
    minutes_by_job = {}

    @production.each do |name, config|
      schedule = config["schedule"]

      # Parse cron-style (e.g., "3,33 * * * *")
      if schedule.match?(/^\d/)
        mins = schedule.split(" ").first.split(",")
        minutes_by_job[name] = mins
      # Parse "every hour at :05"
      elsif (m = schedule.match(/every hour at :(\d+)/))
        minutes_by_job[name] = [m[1]]
      # Parse "every day at H:MMam/pm"
      elsif (m = schedule.match(/at (\d+):(\d+)(am|pm)/))
        minutes_by_job[name] = [m[2]]
      end
    end

    # Check for collisions among hourly jobs (jobs that run every hour)
    hourly_jobs = minutes_by_job.select { |name, _| @production[name]["schedule"].include?("every hour") || @production[name]["schedule"].match?(/^\d/) }
    seen_minutes = {}
    hourly_jobs.each do |name, mins|
      mins.each do |min|
        if seen_minutes[min]
          flunk "Minute :#{min} collision between '#{seen_minutes[min]}' and '#{name}'"
        end
        seen_minutes[min] = name
      end
    end
    assert seen_minutes.any?, "Expected at least one hourly job with a parsed minute"
  end
end
