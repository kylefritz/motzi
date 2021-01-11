class PickupDay < ApplicationRecord
  belongs_to :menu
  has_many :order_items

  def self.for_pickup_at(pickup_at)
    PickupDay.find_by("date_trunc('day', pickup_at) = ?", pickup_at.to_date)
  end

  def pickup_day
    Date::DAYS_INTO_WEEK.invert[pickup_at.wday].to_s.titleize
  end

  def pickup_day_abbr
    I18n.t('date.abbr_day_names')[pickup_at.wday]
  end
end
