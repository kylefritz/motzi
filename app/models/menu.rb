class Menu < ApplicationRecord
  has_many :menu_items, dependent: :delete_all
  has_many :items, through: :menu_items
  has_many :orders
  has_many :messages, class_name: "Ahoy::Message"
  has_paper_trail
  default_scope { order("LOWER(week_id) desc") }

  def self.current
    Menu.find(Setting.menu_id)
  end

  def make_current!
    Setting.menu_id = self.id
  end

  def current?
    self.id == Setting.menu_id
  end

  def add_skip!
    return if self.items.include?(Item.skip)

    self.menu_items.create!(item: Item.skip)
  end

  def publish_to_subscribers!
    self.make_current!
    self.touch :emailed_at # audit email was sent
    self.add_skip!
    SendWeeklyMenuJob.perform_now.size
  end
end
