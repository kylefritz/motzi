class PickupDay < ApplicationRecord
  belongs_to :menu
  has_many :order_items, dependent: :destroy
  has_many :menu_item_pickup_days, dependent: :destroy
  default_scope { order("pickup_at") }
  has_paper_trail

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

  def deadline_data
    {
      pickup_day: pickup_at.strftime('%a'),
      pickup_date: pickup_at.strftime('%b %-d'),
      pickup_time: pickup_at.strftime('%-l:%M %p').gsub(/:00/, '').gsub(/ AM/i, 'a').gsub(/ PM/i, 'p'),
      deadline_day: order_deadline_at.strftime('%a'),
      deadline_date: order_deadline_at.strftime('%b %-d'),
      deadline_time: order_deadline_at.strftime('%-l:%M %p').gsub(/:00/, '').gsub(/ AM/i, 'a').gsub(/ PM/i, 'p')
    }
  end

  def deadline_text
    d = deadline_data
    "#{d[:pickup_day]}, #{d[:pickup_date]} at #{d[:pickup_time]} — order by #{d[:deadline_day]}, #{d[:deadline_date]} at #{d[:deadline_time]}"
  end
end
 