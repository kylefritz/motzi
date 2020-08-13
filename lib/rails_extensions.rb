require 'active_support'
require 'active_support/core_ext/object/json'

class BigDecimal
  # rails encodes pg decimals to string by default
  # instead suffer the *loss of percision* and encode them as floats
  # https://github.com/rails/rails/issues/25017
  def as_json(*)
    to_f
  end
end

class ActiveSupport::TimeWithZone
  def day1_pickup?
    self.wday == Setting.pickup_day1_wday
  end

  def day2_pickup?
    self.wday == Setting.pickup_day2_wday
  end

  def cweek
    self.to_datetime.cweek
  end

  def week_id
    # nudge forward into next week if past 9a on sunday
    wk_nudge = self.wday == 0 && self.hour >= 9 ? 1 :0

    date_time = self + wk_nudge.days
    yr = date_time.end_of_week.year.to_s[2..]
    wk = date_time.cweek.to_s.rjust(2, "0")
    [yr, wk].join("w")
  end
end

class ActiveSupport::TimeZone
  def from_week_id(week_id)
    yr, num_weeks = week_id.split('w')
    num_weeks = num_weeks.to_i - 1
    jan1 = ActiveSupport::TimeZone['America/New_York'].parse("20#{yr}-01-01 9:00 AM")
    jan1.beginning_of_week + num_weeks.weeks - 1.day + 9.hours
  end
end
