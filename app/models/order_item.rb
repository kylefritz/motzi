class OrderItem < ApplicationRecord
  belongs_to :item
  belongs_to :order
  has_paper_trail

  def name
    "OrderItem##{id} in Order ##{order_id}"
  end
end
