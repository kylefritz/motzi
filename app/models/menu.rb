class Menu < ApplicationRecord
  has_many :menu_items, dependent: :destroy
  has_many :pickup_days, dependent: :destroy
  has_many :items, through: :menu_items
  has_many :orders
  has_many :order_items, through: :orders
  has_many :messages, class_name: "Ahoy::Message"
  has_paper_trail
  default_scope { order("LOWER(week_id) desc") }

  def self.current
    Menu.find(Setting.menu_id)
  end
  def self.for_current_week_id
    Menu.find_by(week_id: Time.zone.now.week_id)
  end

  def make_current!
    Setting.menu_id = self.id
  end

  def current?
    self.id == Setting.menu_id
  end

  def for_current_week_id?
    self.week_id == Time.zone.now.week_id
  end

  def can_publish?
    self.week_id >= Time.zone.now.week_id
  end

  def item_counts
    # TODO: how should we represent this?
    day_item_counts = SqlQuery.new(:ordered_items_counts, menu_id: self.id).execute
    # pickup_days = self.pickup_days.all

    {}.tap do |counts|
      day_item_counts.each do |r|
        pickup_day_id = r["pickup_day_id"]
        item_id = r["item_id"]
        num_items = r["sum"]

        if counts[item_id].nil?
          counts[item_id] = {}
        end
        counts[item_id][pickup_day_id] = num_items
      end
    end
  end

  def item_counts_by_pickup_day
    day_item_counts = SqlQuery.new(:ordered_items_counts, menu_id: self.id).execute
    {}.tap do |counts|
      day_item_counts.each do |r|
        pickup_day_id = r["pickup_day_id"]
        item_id = r["item_id"]
        num_items = r["sum"]

        if counts[pickup_day_id].nil?
          counts[pickup_day_id] = {}
        end
        counts[pickup_day_id][item_id] = num_items
      end
    end
  end

  def subscriber_note_html
    @subscriber_note_html ||= MARKDOWN.render(self.subscriber_note || '').html_safe
  end

  def menu_note_html
    @menu_note_html ||= MARKDOWN.render(self.menu_note || '').html_safe
  end

  def day_of_note_html
    @day_of_note_html ||= MARKDOWN.render(self.day_of_note || '').html_safe
  end

  def publish_to_subscribers!
    unless can_publish?
      throw "can only publish_to_subscribers for current week's menu or future week's menu"
    end
    self.make_current!
    self.touch :emailed_at # create audit that email was sent
    SendWeeklyMenuJob.users_to_email_count(self).tap do
      SendWeeklyMenuJob.perform_later
    end
  end

  def ordering_closed?
    Time.zone.now > self.pickup_days.maximum(:order_deadline_at)
  end

  MARKDOWN = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
end
