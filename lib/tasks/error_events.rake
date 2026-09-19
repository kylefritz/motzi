namespace :error_events do
  desc "List resolved production errors that no test cites (error_events #<id>). Run: heroku run rake error_events:untested"
  task :untested, [ :days ] => :environment do |_, args|
    days = (args[:days] || 90).to_i
    untested = RegressionTestIndex.new.untested_resolved(since: days.days.ago)

    if untested.empty?
      puts "Every error resolved in the last #{days} days has a regression test."
      next
    end

    puts "#{untested.size} resolved error group(s) from the last #{days} days with no test citing them:"
    puts
    untested.each do |g|
      puts "  error_events ##{g[:latest_id]}  #{g[:error_class]}: #{g[:message].truncate(90)}"
      puts "    resolved #{g[:resolved_at]&.to_date}  fingerprint #{g[:fingerprint]}"
    end
    puts
    puts "Write a test that reproduces each, and cite it: # Regression for error_events #<id>"
  end
end
