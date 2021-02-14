class PickupDay < ApplicationRecord
  belongs_to :menu
  has_many :order_items

  def self.for_pickup_at(dt) self.for_date_trunc('pickup_at', dt) end
  def self.for_order_deadline_at(dt) self.for_date_trunc('order_deadline_at', dt) end

  def self.for_date_trunc(field, dt)
    PickupDay.find_by("date_trunc('day', #{field}) = ?", dt.utc.to_date)
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
    pickup_str = pickup_at.strftime('%a (%m/%d)')
    deadline_str = order_deadline_at.strftime('%-l:%M %p %a (%m/%d)')
    "for #{pickup_str} pickup, order by #{deadline_str}"
  end
end
