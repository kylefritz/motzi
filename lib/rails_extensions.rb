class ActiveSupport::TimeWithZone
  def is_first_half?
    self.wday == 2 # tues
  end

  def is_second_half?
    self.wday == 4 # thurs
  end

  def too_early?
    self.hour < 7 # before 7am
  end

  def cweek
    self.to_datetime.cweek
  end

  def week_id
    "#{self.year.to_s[2..]}w#{self.cweek.to_s.rjust(2, "0")}"
  end
end

class ActiveSupport::TimeZone
  def from_week_id(week_id)
    yr, num_weeks = week_id.split('w')
    num_weeks = num_weeks.to_i - 1
    jan1 = DateTime.parse("20#{yr}-01-01 9:00 AM EST")
    jan1.beginning_of_week + num_weeks.weeks - 1.day + 9.hours
  end
end
