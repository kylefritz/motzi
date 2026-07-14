class ContactMessage < ApplicationRecord
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, length: { maximum: 255 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :message, presence: true, length: { maximum: 5000 }
  validates :phone, length: { maximum: 30 }, allow_blank: true
  validates :user_agent, length: { maximum: 512 }, allow_blank: true
end
