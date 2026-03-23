class ErrorFeedback < ApplicationRecord
  validates :page_type, presence: true, inclusion: { in: %w[404 422 500] }
  validates :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
