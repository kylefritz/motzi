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
    num_weeks = week_id.split('w').second.to_i - 1
    self.now.beginning_of_year.beginning_of_week + num_weeks.weeks + 9.hours - 1.day
  end
end
