class Menu < ApplicationRecord
  has_many :menu_items
  has_many :items, through: :menu_items
  has_paper_trail

  def self.current
    Menu.where(is_current: true).first
  end

  def make_current!
    # mark the rest of the menus as "not current"
    Menu.update_all(is_current: false)

    self.update!(is_current: true)
  end

  def publish_to_subscribers!(finalized_by_user_id)
    self.make_current!

    # send the email
    # TODO: might want to send all these emails individually?
    MenuMailer.with(menu: self).menu_email.deliver_now

    ActiveAdmin::Comment.create!(namespace: 'admin', body: 'Menu was emailed to subscribers',
                                 resource_type: "Menu", resource_id: self.id,
                                 author_type: "User", author_id: finalized_by_user_id)
  end
end
