class QueueDemoJob < ApplicationJob
  queue_as :default

  def perform(enqueued_by_user_id = nil)
    Rails.logger.info("QueueDemoJob started by user_id=#{enqueued_by_user_id || 'unknown'}")
    sleep 20
    Rails.logger.info("QueueDemoJob finished")
  end
end
