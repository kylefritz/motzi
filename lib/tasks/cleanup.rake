namespace :cleanup do
  desc "Trim ahoy visits and events to last 90 days"
  task trim_analytics: :environment do
    TrimAnalyticsJob.perform_now
  end
end
