class OrderItem < ApplicationRecord
  belongs_to :item
  belongs_to :order
  belongs_to :pickup_day
  has_paper_trail
  scope :requires_pickup, -> { where("item_id != ?", Item::PAY_IT_FORWARD_ID) }

  def name
    "OrderItem ##{id} in Order ##{order_id}"
  end

  def day
    if self.pay_it_forward?
      return nil
    end

    self.pickup_day.day_str
  end

  def pay_it_forward?
    self.item_id == Item::PAY_IT_FORWARD_ID
  end
end
