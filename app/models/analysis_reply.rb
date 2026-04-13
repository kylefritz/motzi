class AnalysisReply < ApplicationRecord
  belongs_to :anomaly_analysis
  belongs_to :user, optional: true

  validates :body, :author_email, presence: true
  validates :message_id, uniqueness: true, allow_nil: true

  enum :source, { email: 0, admin: 1 }
end
