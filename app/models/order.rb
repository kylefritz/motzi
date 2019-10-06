class Order < ApplicationRecord
  belongs_to :user
  belongs_to :menu
  has_many :order_items
  has_many :items, through: :order_items
  has_paper_trail
end
