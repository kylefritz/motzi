class MenuItem < ApplicationRecord
  belongs_to :item
  belongs_to :menu
  has_paper_trail
  scope :is_not_add_on, -> { where("is_add_on = false") }
end
