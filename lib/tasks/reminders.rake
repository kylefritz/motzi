namespace :reminders do
  desc "Reminder to order before sunday midnight deadline"
  task :havent_ordered => :environment do
    if Setting.automated_reminder_emails?
      SendHaventOrderedReminderJob.perform_now
    else
      Rails.logger.warn "SendHaventOrderedReminderJob automated_reminder_emails disabled; skipping"
    end
  end

  desc "Assigns bakers choice to ppl that havent ordered"
  task :assign_bakers_choice => :environment do
    if Setting.automated_reminder_emails?
      # TODO: enable bakers choice job?
      # CreateBakersChoiceOrdersJob.perform_now
    else
      Rails.logger.warn "CreateBakersChoiceOrdersJob automated_reminder_emails disabled; skipping"
    end
  end

  desc "Morning, day-of reminder to pick-up your bread"
  task :pick_up_bread => :environment do
    if Setting.automated_reminder_emails?
      SendDayOfReminderJob.perform_now
    else
      Rails.logger.warn "SendDayOfReminderJob automated_reminder_emails disabled; skipping"
    end
  end
end
