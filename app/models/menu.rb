class Menu < ApplicationRecord
  has_many :menu_items
  has_many :items, through: :menu_items
  has_paper_trail

  def self.current
    Menu.where(is_current: true).first
  end

  def make_current!
    unless self.is_current
      # mark the rest of the menus as "not current"
      Menu.update_all(is_current: false)

      self.update!(is_current: true)
    end
  end

  def publish_to_subscribers!(finalized_by_user_id)
    self.make_current!

    # email each individual user
    User.for_weekly_email.map do |user|
      MenuMailer.with(menu: self, user: user).weekly_menu.deliver_now
    end.tap do |emails|
      # audit that email was sent
      self.update(emailed_at: DateTime.now)
      ActiveAdmin::Comment.create(namespace: 'admin', body: "Menu '#{name}' was emailed to #{emails.size} subscribers",
                                  resource_type: "Menu", resource_id: self.id,
                                  author_type: "User", author_id: finalized_by_user_id)
    end
  end
end
