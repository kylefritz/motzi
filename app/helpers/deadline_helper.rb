module DeadlineHelper
  def order_by_for_day_num(day_num)
    pickup_day = Setting.send("pickup_day#{day_num}".to_sym)
    pickup_wday = Setting.send("pickup_day#{day_num}_wday".to_sym)

    deadline = Time.zone.now.beginning_of_week - 1.day + pickup_wday.days - Setting.leadtime_hours.hours

    "#{deadline.strftime("%l%P %A").strip} for #{pickup_day} pickup"
  end

  def ordering_deadline_text(menu)
    menu.pickup_days.map(&:deadline_text).join(" or\n")
  end
end
