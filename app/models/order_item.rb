class OrderItem < ApplicationRecord
  belongs_to :item
  belongs_to :order
  has_paper_trail
  scope :day1_pickup, -> { where("day1_pickup is TRUE") }
  scope :day2_pickup, -> { where("day1_pickup is FALSE") }

  def name
    "OrderItem ##{id} in Order ##{order_id}"
  end
end
