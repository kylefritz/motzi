class OrderItem < ApplicationRecord
  belongs_to :item
  belongs_to :order
  has_paper_trail

  def name
    "#{item&.name} in Order ##{order_id}"
  end
end
