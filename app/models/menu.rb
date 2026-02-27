class Menu < ApplicationRecord
  has_many :menu_items, dependent: :destroy
  has_many :pickup_days, dependent: :destroy
  has_many :items, through: :menu_items
  has_many :orders
  has_many :order_items, through: :orders
  has_many :messages, class_name: "Ahoy::Message"
  has_paper_trail
  default_scope { order("LOWER(week_id) desc") }

  enum :menu_type, { regular: 'regular', holiday: 'holiday' }

  def self.current
    Menu.find(Setting.menu_id)
  end

  def self.current_holiday
    return nil unless Setting.holiday_menu_id.present?
    Menu.find(Setting.holiday_menu_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def self.for_current_week_id
    Menu.find_by(week_id: Time.zone.now.week_id)
  end

  def make_current!
    if holiday?
      Setting.holiday_menu_id = self.id
    else
      Setting.menu_id = self.id
    end
  end

  def current?
    if holiday?
      self.id == Setting.holiday_menu_id
    else
      self.id == Setting.menu_id
    end
  end

  def for_current_week_id?
    self.week_id == Time.zone.now.week_id
  end

  def can_publish?
    if holiday?
      latest_deadline.present? && Time.zone.now < latest_deadline
    else
      self.week_id >= Time.zone.now.week_id
    end
  end

  # Opens holiday menu for pre-orders — NO EMAIL, intentionally.
  #
  # IMPORTANT: This does NOT send any notification to subscribers.
  # Bakers announce holiday pre-orders in the regular weekly menu's subscriber_note.
  # This is intentional: bakers control the announcement timing themselves.
  #
  # Contrast: publish_to_subscribers! (regular menus) makes current AND sends the weekly email.
  def open_for_orders!
    raise "open_for_orders! is only for holiday menus. Use publish_to_subscribers! for regular menus." unless holiday?
    raise "Cannot open: no pickup days set or all deadlines have passed." unless can_publish?
    make_current!
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

  def copy_from(original_menu, options = {})
    copy_notes_from(original_menu, options)

    pickup_day_map = map_pickup_days_from(original_menu)

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
          pickup_day_id: pickup_day_map[mipud.pickup_day_id],
          limit: mipud.limit&.positive? ? mipud.limit : nil,
        )
      end
    end
  end

  def map_pickup_days_from(original_menu)
    # we intentionally don't support multiple pickup days on the same weekday

    original_week_start = Time.zone.from_week_id(original_menu.week_id)
    target_week_start = Time.zone.from_week_id(self.week_id)

    target_days_by_wday = self.pickup_days.index_by { |day| day.pickup_at.wday }

    {}.tap do |map|
      original_menu.pickup_days.each do |pickup_day|
        target_day = target_days_by_wday[pickup_day.pickup_at.wday]
        if target_day.nil?
          target_day = pickup_days.create!(
            pickup_at: target_week_start + (pickup_day.pickup_at - original_week_start),
            order_deadline_at: target_week_start + (pickup_day.order_deadline_at - original_week_start),
          )
          target_days_by_wday[pickup_day.pickup_at.wday] = target_day
        end

        map[pickup_day.id] = target_day.id
      end
    end
  end

  def copy_notes_from(original_menu, options)
    attrs = {}

    # for each note, only copy if note is empty in this menu
    if options[:copy_subscriber_note] && subscriber_note.blank?
      attrs[:subscriber_note] = original_menu.subscriber_note
    end
    if options[:copy_menu_note] && menu_note.blank?
      attrs[:menu_note] = original_menu.menu_note
    end
    if options[:copy_day_of_note] && day_of_note.blank?
      attrs[:day_of_note] = original_menu.day_of_note
    end

    update!(attrs) if attrs.any?
  end

  MARKDOWN = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
end
