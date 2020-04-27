class Item < ApplicationRecord
  has_many :menu_items
  has_many :menus, through: :menu_items
  has_paper_trail
  has_one_attached :image
  default_scope { order("LOWER(name)") }

  PAY_IT_FORWARD_ID = -1
  def self.pay_it_forward
    self.find_by(id: PAY_IT_FORWARD_ID)
  end

  def image_path
    if self.image.attached?
      Rails.application.routes.url_helpers.rails_blob_path(self.image, only_path: true)
    end
  end
end
