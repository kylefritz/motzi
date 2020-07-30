namespace :reminders do
  desc "Reminder to order before sunday midnight deadline"
  task :havent_ordered => :environment do
    if Setting.automated_reminder_emails?
      SendHaventOrderedReminderJob.perform_now
    else
      Rails.logger.warn "SendHaventOrderedReminderJob automated_reminder_emails disabled; skipping"
    end
  end

  desc "Morning, day-of reminder to pick-up your order"
  task :pick_up_bread => :environment do
    if Setting.automated_reminder_emails?
      SendDayOfReminderJob.perform_now
    else
      Rails.logger.warn "SendDayOfReminderJob automated_reminder_emails disabled; skipping"
    end
  end
end
