class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  def add_comment!(resource, comment)
    Rails.logger.info comment
    ActiveAdmin::Comment.create!(body: comment, namespace: 'admin', resource: resource, author: User.system)
  end
end
