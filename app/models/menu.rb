class Menu < ApplicationRecord
  has_many :menu_items, dependent: :delete_all
  has_many :items, through: :menu_items
  has_many :orders
  has_many :messages, class_name: "Ahoy::Message"
  has_paper_trail

  def self.current
    Menu.find(Setting.menu_id)
  end

  def make_current!
    Setting.menu_id = self.id
  end

  def current?
    self.id == Setting.menu_id
  end

  def publish_to_subscribers!
    self.make_current!

    # email each individual user
    User.for_weekly_email.map do |user|
      MenuMailer.with(menu: self, user: user).weekly_menu.deliver_later
    end.tap do |emails|
      # audit that email was sent
      self.update(emailed_at: DateTime.now)
    end
  end
end
