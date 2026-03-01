class QueueDemoJob < ApplicationJob
  queue_as :default

  def perform(enqueued_by_user_id = nil)
    user_id = enqueued_by_user_id || "unknown"
    Rails.logger.info("QueueDemoJob starting (user_id=#{user_id})")
    Rails.logger.info("QueueDemoJob sleeping for 20 seconds (user_id=#{user_id})")
    sleep 20
    Rails.logger.info("QueueDemoJob done (user_id=#{user_id})")
  end
end
