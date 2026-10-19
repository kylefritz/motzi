class Item < ApplicationRecord
  has_many :menu_items
  has_many :menus, through: :menu_items
  # restrict: order_items are the financial record of what was sold — archive
  # items instead of deleting (admin's delete_item already checks deletable?)
  has_many :order_items, dependent: :restrict_with_error
  has_paper_trail
  has_one_attached :image
  default_scope { order(Arel.sql("LOWER(items.name)")) }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  def deletable?
    menu_items.none? && order_items.none?
  end

  PAY_IT_FORWARD_ID = -1
  def self.pay_it_forward
    self.find_by(id: PAY_IT_FORWARD_ID)
  end

  def pay_it_forward?
    self.id == PAY_IT_FORWARD_ID
  end

  # A PDF upload is shown as a picture of its first page, this big at most.
  MENU_IMAGE_SIZE = { resize_to_limit: [ 1200, 1200 ] }.freeze

  def image_path
    return unless image.attached?

    url_helpers = Rails.application.routes.url_helpers
    if image.image? || !image.previewable?
      url_helpers.rails_blob_path(image, only_path: true)
    else
      url_helpers.rails_representation_path(image.representation(MENU_IMAGE_SIZE), only_path: true)
    end
  end
end
