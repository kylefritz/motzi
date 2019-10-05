class Order < ApplicationRecord
  belongs_to :user
  belongs_to :menu
  has_many :order_items
end
