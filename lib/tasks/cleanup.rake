namespace :cleanup do
  desc "Trim ahoy visits and events to last 90 days"
  task trim_analytics: :environment do
    cutoff = 90.days.ago
    puts "Trimming analytics data older than #{cutoff.to_date}..."

    deleted = Ahoy::Event.where("time < ?", cutoff).delete_all
    puts "  ahoy_events: #{deleted} deleted"

    deleted = Ahoy::Visit.where("started_at < ?", cutoff).delete_all
    puts "  ahoy_visits: #{deleted} deleted"

    puts "Done."
  end
end
