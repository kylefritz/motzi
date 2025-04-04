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
  scope :subscribers, -> { not_owners.where(subscriber: true) }
  scope :nonsubscribers, -> { where(subscriber: false) }
  scope :opt_in, -> { where(opt_in: true) }
  scope :owners, -> {where(email: [MAYA_EMAIL, RUSSELL_EMAIL])}
  scope :not_owners, -> {where.not(email: [MAYA_EMAIL, RUSSELL_EMAIL])}
  scope :admin, -> {where(is_admin: true)}
  scope :spam, -> {where(id: SqlQuery.new(:spam_user_ids).execute.pluck("id"))}
  before_validation(on: :create) do
    # if no password, set random passwords on user
    self.password = SecureRandom.base64(16) if self.password.blank?
  end
  before_validation do
    self.email = self.email.strip.downcase
  end

  def credits
    SqlQuery.new(:user_credits, user_ids: [self.id]).execute.first["credit_balance"]
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
    menu_orders = orders.subscriber.where(menu_id: menu_id).includes(order_items: [:item])
    if menu_orders.size > 1
      logger.warn "user=#{self.id} has more than 1 order for menu #{menu_id}"
    end
    menu_orders.last
  end

  def email_list
    [email, additional_email].filter(&:present?).join(', ')
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
  SYSTEM_ID = 0
  def self.system
    User.find_by(id: SYSTEM_ID)
  end
end
