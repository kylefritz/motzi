class Order < ApplicationRecord
  belongs_to :user
  belongs_to :menu
  has_many :order_items, dependent: :delete_all
  has_many :items, through: :order_items
  has_paper_trail
  visitable :ahoy_visit
  scope :with_feedback, -> { where("COALESCE(TRIM(feedback), '') <> ''") }
  scope :with_comments, -> { where("COALESCE(TRIM(comments), '') <> '' AND comments <> 'Baker''s Choice'") }
  scope :day1_pickup, -> { joins(:user).where('(day1_pickup_maybe is NULL AND users.day1_pickup is true ) OR day1_pickup_maybe is true') }
  scope :day2_pickup, -> { joins(:user).where('(day1_pickup_maybe is NULL AND users.day1_pickup is false) OR day1_pickup_maybe is false') }

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

  def pickup_day
    day1_pickup? ? Setting.pickup_day1 : Setting.pickup_day2
  end

  def day1_pickup?
    # if value on order is nil, fall back to value on user
    if day1_pickup_maybe.nil?
      user.day1_pickup?
    else
      day1_pickup_maybe
    end
  end

  def day2_pickup?
    !day1_pickup?
  end
end
