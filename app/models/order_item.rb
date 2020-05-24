class OrderItem < ApplicationRecord
  belongs_to :item
  belongs_to :order
  has_paper_trail
  scope :requires_pickup, -> { where("item_id != ?", Item::PAY_IT_FORWARD_ID) }
  scope :day1_pickup, -> { requires_pickup.where("day1_pickup is TRUE") }
  scope :day2_pickup, -> { requires_pickup.where("day1_pickup is FALSE") }

  def name
    "OrderItem ##{id} in Order ##{order_id}"
  end

  def day
    if self.item_id == Item::PAY_IT_FORWARD_ID
      return nil
    end

    self.day1_pickup ? Setting.pickup_day1 : Setting.pickup_day2
  end
end
