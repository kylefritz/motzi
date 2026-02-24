namespace :cleanup do
  desc "Trim ahoy visits and events to last 90 days"
  task trim_analytics: :environment do
    cutoff = 90.days.ago
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

    puts "Done."
  end
end
