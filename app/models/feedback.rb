class Feedback < ApplicationRecord
  SOURCES = %w[404 422 500 menu general contact].freeze

  # user_agent and url come from request headers, not user input — silently
  # truncate so a long browser UA or referer can't make save fail and lose
  # the submission.
  before_validation :truncate_request_metadata

  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :message, presence: true, length: { maximum: 5000 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :url, length: { maximum: 2048 }
  validates :user_agent, length: { maximum: 512 }
  validates :name, length: { maximum: 255 }
  validates :phone, length: { maximum: 50 }

  private

  def truncate_request_metadata
    self.user_agent = user_agent.truncate(512) if user_agent.present?
    self.url = url.truncate(2048) if url.present?
  end
end
