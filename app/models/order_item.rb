class OrderItem < ApplicationRecord
  belongs_to :item
  belongs_to :order
  belongs_to :pickup_day
  has_paper_trail
  scope :requires_pickup, -> { where("item_id != ?", Item::PAY_IT_FORWARD_ID) }

  # credits/price are immutable snapshots of the item's pricing at order time,
  # so later repricing an item never changes past order totals or balances (#170)
  before_validation :snapshot_item_pricing, on: :create

  def snapshot_item_pricing
    return if item.blank?
    self.credits ||= item.credits
    self.price ||= item.price
  end

  def name
    "OrderItem ##{id} in Order ##{order_id}"
  end

  def day
    self.pickup_day.day_str
  end

  def pay_it_forward?
    self.item_id == Item::PAY_IT_FORWARD_ID
  end
end
