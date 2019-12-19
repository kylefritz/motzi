class User < ApplicationRecord
  include Hashid::Rails
  default_scope { order("LOWER(first_name), LOWER(last_name)") }
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :trackable
  has_many :credit_entries
  has_many :messages, class_name: "Ahoy::Message", as: :user
  has_many :orders # must come before order_items
  has_many :order_items, through: :orders
  has_many :visits, class_name: "Ahoy::Visit"
  has_paper_trail
  scope :for_weekly_email, -> { where(send_weekly_email: true) }
  scope :tuesday_pickup, -> { where(tuesday_pickup: true) }
  scope :thursday_pickup, -> { where(tuesday_pickup: false) }
  scope :must_order_weekly, -> { where("breads_per_week >= 1").where.not(email: [MAYA_EMAIL, RUSSELL_EMAIL]) }
  scope :every_other_week, -> { where("breads_per_week = 0.5") }
  scope :owners, -> {where(email: [MAYA_EMAIL, RUSSELL_EMAIL])}
  before_validation(on: :create) do
    # if no password, set random passwords on user
    self.password = SecureRandom.base64(16) if self.password.blank?
  end
  def self.for_bakers_choice
    # users who havent ordered but must
    must_order = User.must_order_weekly.pluck(:id)
    have_ordered = Order.for_current_menu.where(user_id: must_order).pluck(:user_id)
    User.where(id: must_order - have_ordered)
  end

  def thursday_pickup?
    !self.tuesday_pickup?
  end

  def must_order_weekly?
    self.breads_per_week >= 1
  end

  def credits
    # TODO: not handing credit expiration
    credits_purchased = credit_entries.pluck('quantity').sum
    credits_used = order_items.not_skip.count
    credits_purchased - credits_used
  end

  def authenticate(password)
    Devise::Encryptor.compare(User, self.encrypted_password, password)
  end

  def name
    [first_name, last_name].compact.join(' ').presence || email
  end

  def current_order
    order_for_menu(Menu.current.id)
  end

  def order_for_menu(menu_id)
    orders.where(menu_id: menu_id).includes(order_items: [:item]).first
  end

  #
  # vanity users
  #
  def self.kyle
    User.find_by(email: 'kyle.p.fritz@gmail.com')
  end
  MAYA_EMAIL = 'mayapamela@gmail.com'
  def self.maya
    User.find_by(email: MAYA_EMAIL)
  end
  RUSSELL_EMAIL = 'trimmer.russell@gmail.com'
  def self.russell
    User.find_by(email: RUSSELL_EMAIL)
  end
end
