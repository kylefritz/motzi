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
      # Pass the specific menu ID to the job
      SendWeeklyMenuJob.perform_later(id)
    end
  end

  def ordering_closed?
    Time.zone.now > self.latest_deadline
  end

  def earliest_deadline
    self.pickup_days.minimum(:order_deadline_at)
  end

  def latest_deadline
    self.pickup_days.maximum(:order_deadline_at)
  end

  def sorted_menu_items(includes: nil)
    my_menu_items = self.menu_items
    if includes.present?
      my_menu_items = my_menu_items.includes(includes)
    end

    my_menu_items.sort_by {|mi| mi.sort_order.nil? ? 1_000 : mi.sort_order}
  end

  def copy_from(original_menu)
    if self.pickup_days.empty?
      copy_pickup_days_from(original_menu)
    end

    if original_menu.pickup_days.count > self.pickup_days.count
      raise "Can't map onto fewer pickup days"
    end

    # make a lookup between old pick_up days & new pick_up days
    new_to_old = Hash[original_menu.pickup_days.zip(self.pickup_days).map do |pud, new_pud|
      [pud.id, new_pud.id]
    end]

    # if there are already items in this menu, append these new ones to the end by offsetting the sort order index
    sort_offset = self.menu_items.pluck(:sort_order).compact.max || 0

    original_menu.sorted_menu_items.each_with_index do |original_mi, index|
      new_mi = self.menu_items.create!(
        item_id: original_mi.item_id,
        subscriber: original_mi.subscriber,
        marketplace: original_mi.marketplace,
        sort_order: sort_offset + index,
      )

      original_mi.menu_item_pickup_days.each do |mipud|
        new_mi.menu_item_pickup_days.create!(
          pickup_day_id: new_to_old[mipud.pickup_day_id],
          limit: mipud.limit,
        )
      end
    end
  end

  def copy_pickup_days_from(original_menu)
    original_week_start = Time.zone.from_week_id(original_menu.week_id)
    target_week_start = Time.zone.from_week_id(self.week_id)

    original_menu.pickup_days.each do |pickup_day|
      pickup_days.create!(
        pickup_at: target_week_start + (pickup_day.pickup_at - original_week_start),
        order_deadline_at: target_week_start + (pickup_day.order_deadline_at - original_week_start),
      )
    end
  end

  MARKDOWN = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
end
