class Order < ApplicationRecord
  belongs_to :user
  belongs_to :menu
  has_many :order_items, dependent: :delete_all
  has_many :items, through: :order_items
  has_paper_trail

  def self.for_current_menu
    self.for_menu_id(Menu.current.id)
  end

  def self.for_menu_id(menu_id)
    self.includes(:user, :items).where(menu_id: menu_id).where("user_id is not null")
  end

  def name
    "Order ##{id}"
  end

  delegate :is_first_half?, to: :user
end
