class MenuItem < ApplicationRecord
  belongs_to :item
  belongs_to :menu
  has_paper_trail
end
