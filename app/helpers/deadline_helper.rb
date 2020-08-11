module DeadlineHelper
  def pickup_day1_deadline_day
    Date::DAYS_INTO_WEEK.invert[Setting.pickup_day1_deadline_wday].to_s.titlecase
  end
  def pickup_day2_deadline_day
    Date::DAYS_INTO_WEEK.invert[Setting.pickup_day2_deadline_wday].to_s.titlecase
  end
  def deadline_time
    "9pm" #"midnight"
  end
  def day_to_order_by_text
    "#{deadline_time} #{pickup_day1_deadline_day} for #{Setting.pickup_day1} pickup or #{deadline_time} #{pickup_day2_deadline_day} for #{Setting.pickup_day2} pickup"
  end
end
