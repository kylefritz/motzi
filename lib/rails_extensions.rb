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
  def cweek
    # cweek starts on monday, we start our weeks on sunday
    # https://stackoverflow.com/questions/6720736/week-number-of-the-year-kinda
    (to_datetime + 1.day).cweek
  end

  def week_id
    effective_yr = (if cweek == 1
      (self + 1.day).end_of_week.year
    elsif cweek > 51
      self.beginning_of_week.year
    else
      self.year
    end)

    yr = effective_yr.to_s[2..]
    wk = cweek.to_s.rjust(2, '0')
    [yr, wk].join('w')
  end

  def prev_week_id
    (self - 1.week).week_id
  end
end

class ActiveSupport::TimeZone
  def from_week_id(week_id)
    yr, num_weeks = week_id.split('w')

    week1 = ActiveSupport::TimeZone['America/New_York'].parse("20#{yr}-01-01")
    if week1.cweek == 53
      week1 = week1.beginning_of_week + 7.days
    end

    week_time = week1 + (num_weeks.to_i - 1).weeks
    week_time.beginning_of_week - 1.day + 9.hours
  end
end
