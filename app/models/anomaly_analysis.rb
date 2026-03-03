class AnomalyAnalysis < ApplicationRecord
  belongs_to :user, optional: true

  validates :week_id, :result, :trigger, presence: true

  scope :for_week, ->(week_id) { where(week_id: week_id) }
end
