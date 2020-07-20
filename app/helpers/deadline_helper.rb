module DeadlineHelper
  def pickup_day1_deadline_day
    Date::DAYS_INTO_WEEK.invert[Setting.pickup_day1_deadline_wday].to_s.titlecase
  end
  def pickup_day2_deadline_day
    Date::DAYS_INTO_WEEK.invert[Setting.pickup_day2_deadline_wday].to_s.titlecase
  end
  def day_to_order_by_text
    "midnight #{pickup_day1_deadline_day} for #{Setting.pickup_day1} or midnight #{pickup_day2_deadline_day} for #{Setting.pickup_day2}"
  end
end
