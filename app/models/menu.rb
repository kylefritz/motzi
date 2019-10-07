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

    # email each individual user
    User.all.each do |user|
      MenuMailer.with(menu: self, user: user).weekly_menu.deliver_now
    end

    ActiveAdmin::Comment.create!(namespace: 'admin', body: 'Menu was emailed to subscribers',
                                 resource_type: "Menu", resource_id: self.id,
                                 author_type: "User", author_id: finalized_by_user_id)
  end

  def as_json(options = nil)
    # poor man's serializer
    self.slice(:id, :name, :bakers_note, :created_at).tap do |attrs|
      addons, items = self.menu_items.partition(&:is_add_on?)
      slice_item = -> (mi) { mi.item.as_json.merge(mi.slice(:is_add_on)) }
      attrs[:items] = items.map(&slice_item)
      attrs[:addons] = addons.map(&slice_item)
    end
  end
end
