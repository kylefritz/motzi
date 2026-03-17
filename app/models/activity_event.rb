class ActivityEvent < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, :week_id, :description, presence: true

  scope :for_week, ->(week_id) { where(week_id: week_id) }

  def self.log(action:, week_id:, description:, metadata: {}, user: nil)
    create!(
      action: action,
      week_id: week_id,
      description: description,
      metadata: metadata,
      user: user
    )
  rescue => e
    Rails.logger.error "ActivityEvent.log failed: #{e.message}"
    nil
  end
end
