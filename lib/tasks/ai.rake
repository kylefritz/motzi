namespace :ai do
  task :quiet => :environment do
    ActiveRecord::Base.logger = nil
  end

  desc "Show activity feed prompt for a week (default: current week). Usage: rake motzi:activity_feed_prompt[26w11]"
  task :activity_feed_prompt, [:week_id] => :quiet do |_t, args|
    week_id = args[:week_id] || Time.zone.now.week_id
    feed = ActivityFeed.new(week_id)
    puts feed.to_text(verbose: false)
  end
end
