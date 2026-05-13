class Feedback < ApplicationRecord
  SOURCES = %w[404 422 500 menu general contact].freeze

  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :message, presence: true, length: { maximum: 5000 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :url, length: { maximum: 2048 }
  validates :user_agent, length: { maximum: 512 }
  validates :name, length: { maximum: 255 }
  validates :phone, length: { maximum: 50 }
end
