class AnalysisReply < ApplicationRecord
  belongs_to :anomaly_analysis
  belongs_to :user, optional: true

  validates :body, :author_email, presence: true
  # Uniqueness enforced at DB level (unique index); the controller rescues
  # ActiveRecord::RecordNotUnique for idempotent duplicate handling.

  enum :source, { email: 0, admin: 1 }
end
