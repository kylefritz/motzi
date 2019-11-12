namespace :reminders do
  desc "Reminder to order before sunday midnight deadline"
  task :havent_ordered => :environment do
    SendHaventOrderedReminderJob.perform_now
  end

  desc "Morning, day-of reminder to pick-up your bread"
  task :pick_up_bread => :environment do
    SendDayOfReminderJob.perform_now
  end
end
