class PickupDay < ApplicationRecord
  belongs_to :menu
  has_many :order_items

  def self.for_pickup_at(dt) self.for_date_trunc('pickup_at', dt) end
  def self.for_order_deadline_at(dt) self.for_date_trunc('order_deadline_at', dt) end

  def self.for_date_trunc(field, dt)
    PickupDay.find_by("date_trunc('day', #{field}) = ?", dt.utc.to_date)
  end

  def pickup_day
    Date::DAYS_INTO_WEEK.invert[pickup_at.wday].to_s.titleize
  end

  def pickup_day_abbr
    I18n.t('date.abbr_day_names')[pickup_at.wday]
  end
end
