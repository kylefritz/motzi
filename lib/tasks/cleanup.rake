namespace :cleanup do
  desc "Trim ahoy visits and events to last 90 days"
  task trim_analytics: :environment do
    cutoff = 90.days.ago
    queue_cutoff = ENV.fetch("SOLID_QUEUE_RETENTION_DAYS", 14).to_i.days.ago
    puts "Trimming analytics data older than #{cutoff.to_date}..."

    {
      "ahoy_events" => -> { Ahoy::Event.where("time < ?", cutoff).delete_all },
      "ahoy_visits" => -> { Ahoy::Visit.where("started_at < ?", cutoff).delete_all },
    }.each do |table, cleanup|
      before = ActiveRecord::Base.connection.select_value("SELECT count(*) FROM #{table}")
      deleted = cleanup.call
      after = before - deleted
      puts "  #{table}: #{before} → #{after} (#{deleted} deleted)"
    end

    if defined?(SolidQueue::Job)
      puts "Trimming completed Solid Queue jobs older than #{queue_cutoff.to_date}..."
      before = SolidQueue::Job.where.not(finished_at: nil).count
      deleted = SolidQueue::Job.where("finished_at < ?", queue_cutoff).delete_all
      after = before - deleted
      puts "  solid_queue_jobs (finished): #{before} → #{after} (#{deleted} deleted)"
    end

    puts "Done."
  end
end
