class User < ApplicationRecord
  include Hashid::Rails
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :trackable
  has_many :credit_entries
  has_many :orders
  has_many :order_items, through: :orders
  has_paper_trail
  scope :for_weekly_email, -> { where(send_weekly_email: true) }
  scope :first_half, -> { where(send_weekly_email: true, is_first_half: true) }
  scope :second_half, -> { where(send_weekly_email: true, is_first_half: false) }

  def credits
    # TODO: not handing expiration
    credits_purchased = credit_entries.pluck('quantity').sum
    credits_used = order_items.count
    credits_purchased - credits_used
  end

  def authenticate(password)
    Devise::Encryptor.compare(User, self.encrypted_password, password)
  end

  def name
    [first_name, last_name].compact.join(' ').presence || email
  end

  def current_order
    orders.where(menu_id: Menu.current.id).includes(order_items: [:item]).first
  end

  #
  # vanity users
  #
  def self.kyle
    User.find_by(email: 'kyle.p.fritz@gmail.com')
  end
  def self.adrian
    User.find_by(email: 'adrian.alday@gmail.com')
  end
end
