class Order < ApplicationRecord
  belongs_to :user
  belongs_to :menu
  has_many :order_items, dependent: :delete_all
  has_many :items, through: :order_items
  has_paper_trail
  visitable :ahoy_visit
  scope :with_feedback, -> { where("COALESCE(TRIM(feedback), '') <> ''") }
  scope :with_comments, -> { where("COALESCE(TRIM(comments), '') <> '' AND comments <> 'Baker''s Choice'") }
  scope :day1_pickup, -> { joins(:user).where('users.day1_pickup = true') }
  scope :day2_pickup, -> { joins(:user).where('users.day1_pickup = false') }

  def self.for_current_menu
    self.for_menu_id(Menu.current.id)
  end

  def self.for_menu_id(menu_id)
    self.includes(:user, :items).where(menu_id: menu_id).where("user_id is not null")
  end

  def name
    "Order ##{id}"
  end

  def skip?
    # order is skip if all items are skip
    order_items.map(&:item).reject(&:skip?).blank?
  end

  delegate :day1_pickup?, to: :user
  delegate :day2_pickup?, to: :user
end
