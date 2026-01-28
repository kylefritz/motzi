class PickupDay < ApplicationRecord
  belongs_to :menu
  has_many :order_items, dependent: :destroy
  has_many :menu_item_pickup_days, dependent: :destroy
  default_scope { order("pickup_at") }
  has_paper_trail
  validate :ordering_window_does_not_overlap, if: :validate_ordering_overlap?

  def self.for_pickup_at(dt)
     PickupDay.where("? between pickup_at - interval '8 hours' AND pickup_at + interval '2 hours' ", dt)
  end
  def self.for_order_deadline_at(dt)
    PickupDay.where("? between order_deadline_at - interval '#{Setting.reminder_hours} hours' AND order_deadline_at", dt)
  end

  def day_str
    Date::DAYS_INTO_WEEK.invert[pickup_at.wday].to_s.titleize
  end

  def day_abbr
    I18n.t('date.abbr_day_names')[pickup_at.wday]
  end

  def name
    pickup_at.strftime('%A %m/%d/%y')
  end

  def name_abbr
    pickup_at.strftime('%a %m/%d')
  end

  def deadline_text
    def clean_strftime(time, format)
      time.strftime(format).gsub(/:00/i, '').gsub(/ AM/i, 'a').gsub(/ PM/i, 'p')
    end
    pickup = clean_strftime(pickup_at, '%a %m/%d %-l:%M %p')
    deadline = clean_strftime(order_deadline_at, '%a %m/%d %-l:%M %p')

    "#{pickup} pickup (order by #{deadline})"
  end

  private

  def validate_ordering_overlap?
    menu.present? && !menu.allow_overlap?
  end

  def ordering_window_does_not_overlap
    deadlines = menu.pickup_days.where.not(id: id).pluck(:order_deadline_at)
    deadlines << order_deadline_at if order_deadline_at.present?
    window = menu.ordering_window(deadlines: deadlines)
    return if window.nil?

    conflicts = Menu.includes(:pickup_days).where.not(id: menu.id).select do |other|
      next if other.allow_overlap?
      menu.ordering_window_overlaps?(other, deadlines: deadlines)
    end

    return if conflicts.empty?

    names = conflicts.map(&:name).join(", ")
    errors.add(:base, "Ordering window overlaps with existing menus (#{names})")
  end
end
 
