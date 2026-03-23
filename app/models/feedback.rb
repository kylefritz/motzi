class Feedback < ApplicationRecord
  validates :source, presence: true, inclusion: { in: %w[404 422 500 menu general] }
  validates :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end
