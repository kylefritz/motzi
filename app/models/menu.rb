class Menu < ApplicationRecord
  has_many :menu_items
  has_many :items, through: :menu_items
  has_many :orders
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

  def publish_to_subscribers!(finalized_by_user_id)
    self.make_current!

    # email each individual user
    User.for_weekly_email.map do |user|
      MenuMailer.with(menu: self, user: user).weekly_menu.deliver_now
    end.tap do |emails|
      
      # audit that email was sent
      self.update(emailed_at: DateTime.now)
      # could try to slurp up PaperTrail.request.whodunnit
      ActiveAdmin::Comment.create(namespace: 'admin', body: "Menu '#{name}' was emailed to #{emails.size} subscribers",
                                  resource_type: "Menu", resource_id: self.id,
                                  author_type: "User", author_id: finalized_by_user_id)
    end
  end
end
