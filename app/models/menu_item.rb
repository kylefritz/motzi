class MenuItem < ApplicationRecord
  belongs_to :item
  belongs_to :menu
  has_many :menu_item_pickup_days
  has_paper_trail
end
