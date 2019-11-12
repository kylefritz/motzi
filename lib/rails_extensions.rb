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
end
