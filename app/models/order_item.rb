class OrderItem < ApplicationRecord
  belongs_to :item
  belongs_to :order
  has_paper_trail
  scope :not_skip, -> { where("item_id <> #{Item::SKIP_ID}") }

  def name
    "OrderItem ##{id} in Order ##{order_id}"
  end

  delegate :skip?, to: :item
end
