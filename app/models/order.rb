class Order < ApplicationRecord
  belongs_to :user
  belongs_to :menu
  has_many :order_items
  has_many :items, through: :order_items
  has_paper_trail

  def self.for_current_menu
    self.includes(:user, :items).where(menu_id: Menu.current.id)
  end

  def name
    "Order ##{id} for #{menu&.name} from #{user&.name}"
  end

  delegate :is_first_half?, to: :user
end
