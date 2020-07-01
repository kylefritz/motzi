class User < ApplicationRecord
  include Hashid::Rails
  default_scope { order("LOWER(first_name), LOWER(last_name)") }
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :trackable
  has_many :credit_items, dependent: :destroy
  has_many :messages, class_name: "Ahoy::Message", as: :user
  has_many :orders, dependent: :destroy
  has_many :order_items, through: :orders
  has_many :visits, class_name: "Ahoy::Visit"
  has_paper_trail
  scope :for_weekly_email, -> { where(send_weekly_email: true) }
  scope :no_weekly_email, -> { where(send_weekly_email: false) }
  scope :must_order_weekly, -> { customers.where("breads_per_week >= 1") }
  scope :every_other_week, -> { customers.where("breads_per_week = 0.5") }
  scope :customers, -> { not_owners.for_weekly_email }
  scope :owners, -> {where(email: [MAYA_EMAIL, RUSSELL_EMAIL])}
  scope :not_owners, -> {where.not(email: [MAYA_EMAIL, RUSSELL_EMAIL])}
  scope :admin, -> {where(is_admin: true)}
  before_validation(on: :create) do
    # if no password, set random passwords on user
    self.password = SecureRandom.base64(16) if self.password.blank?
  end
  before_validation do
    self.email = self.email.strip.downcase
  end
  def self.for_bakers_choice
    # users who havent ordered but must
    must_order = User.must_order_weekly.pluck(:id)
    have_ordered = Order.for_current_menu.where(user_id: must_order).pluck(:user_id)
    User.where(id: must_order - have_ordered)
  end

  def must_order_weekly?
    self.breads_per_week >= 1
  end
  def every_other_week?
    !must_order_weekly?
  end

  def credits
    # TODO: not handing credit expiration
    credits_purchased = self.credit_items.pluck('quantity').sum
    credits_used = OrderItem.where(order_id: self.orders.where("stripe_charge_id is null")).pluck('quantity').sum

    credits_purchased - credits_used
  end

  def subscriber?
    self.credit_items.any?
  end

  def authenticate(password)
    Devise::Encryptor.compare(User, self.encrypted_password, password)
  end

  def name
    [first_name, last_name].compact.join(' ').presence || email
  end

  def sort_key
    [last_name, email].compact.join(' ').downcase
  end

  def current_order
    order_for_menu(Menu.current)
  end

  def order_for_menu(menu_id)
    # TODO: can an menu have more than one order?
    menu_orders = orders.where(menu_id: menu_id).includes(order_items: [:item])
    if menu_orders.size > 1
      logger.warn "user=#{self.id} has more than 1 order for menu #{menu_id}"
    end
    menu_orders.first
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
