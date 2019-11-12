class SendHaventOrderedReminderJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "you haven't ordered!"
  end
end
