class Item < ApplicationRecord
  has_many :menu_items
  has_many :menus, through: :menu_items
  has_paper_trail
  has_one_attached :image

  def image_path
    if self.image.attached?
      Rails.application.routes.url_helpers.rails_blob_path(self.image, only_path: true)
    end
  end

  def as_json(options = nil)
    # poor man's serializer
    self.slice(:id, :name, :description).tap do |attrs|      
      attrs[:image] = self.image_path
    end
  end
end
