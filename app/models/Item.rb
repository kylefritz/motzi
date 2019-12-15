class Item < ApplicationRecord
  has_many :menu_items
  has_many :menus, through: :menu_items
  has_paper_trail
  has_one_attached :image
  default_scope { order("LOWER(name)") }

  BAKERS_CHOICE = "Baker's Choice"
  def self.bakers_choice
    self.find_by(name: BAKERS_CHOICE)
  end

  def image_path
    if self.image.attached?
      Rails.application.routes.url_helpers.rails_blob_path(self.image, only_path: true)
    end
  end
end
