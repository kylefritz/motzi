class PickupDay < ApplicationRecord
  belongs_to :menu
  # Order items are the record of what members ordered and what their credits
  # paid for, so a pickup day that has any can't be deleted (same rule as Item).
  # Declared before the associations so it runs before their dependent: :destroy.
  before_destroy :refuse_destroy_with_order_items
  has_many :order_items
  has_many :menu_item_pickup_days, dependent: :destroy
  default_scope { order("pickup_at") }
  has_paper_trail

  # Pickup days whose pickup_at falls on this date in the app's time zone
  # (Eastern). pickup_at is stored in UTC, so a plain ::date cast puts an
  # evening pickup on the next day.
  def self.on_date(date)
    where("(pickup_at AT TIME ZONE 'UTC' AT TIME ZONE ?)::date = ?", Time.zone.tzinfo.identifier, date)
  end

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
    I18n.t("date.abbr_day_names")[pickup_at.wday]
  end

  def name
    pickup_at.strftime("%A %m/%d/%y")
  end

  def name_abbr
    pickup_at.strftime("%a %m/%d")
  end

  # e.g. "Tuesday 11/24", for the confirmation email so a holiday pickup
  # can't be mistaken for an ordinary Tuesday.
  def long_name
    pickup_at.strftime("%A %-m/%-d")
  end

  # e.g. "Tuesday 11/24, pickup after 3pm"
  def pickup_summary
    "#{long_name}, pickup after #{pickup_at.strftime("%-l:%M%P").sub(":00", "")}"
  end

  def deadline_data
    {
      pickup_day: pickup_at.strftime("%a"),
      pickup_date: pickup_at.strftime("%b %-d"),
      pickup_time: pickup_at.strftime("%-l:%M %p").gsub(/:00/, "").gsub(/ AM/i, "a").gsub(/ PM/i, "p"),
      deadline_day: order_deadline_at.strftime("%a"),
      deadline_date: order_deadline_at.strftime("%b %-d"),
      deadline_time: order_deadline_at.strftime("%-l:%M %p").gsub(/:00/, "").gsub(/ AM/i, "a").gsub(/ PM/i, "p")
    }
  end

  def deadline_text
    d = deadline_data
    "#{d[:pickup_day]}, #{d[:pickup_date]} pickup after #{d[:pickup_time]} — order by #{d[:deadline_day]}, #{d[:deadline_date]} at #{d[:deadline_time]}"
  end

  private

  def refuse_destroy_with_order_items
    count = order_items.count
    return if count.zero?

    errors.add(:base, "Can't delete #{name}: #{count} order #{'item'.pluralize(count)} #{count == 1 ? 'is' : 'are'} " \
                      "for this pickup day. Move or remove those orders first.")
    throw :abort
  end
end
