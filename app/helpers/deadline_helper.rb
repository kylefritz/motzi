module DeadlineHelper
  def order_by_for_day_num(day_num)
    pickup_day = Setting.send("pickup_day#{day_num}".to_sym)
    pickup_wday = Setting.send("pickup_day#{day_num}_wday".to_sym)

    deadline = Time.zone.now.beginning_of_week + pickup_wday - Setting.leadtime_days.to_f.days

    "#{deadline.strftime("%I:%M %P %A")} for #{pickup_day} pickup"
  end

  def ordering_deadline_text
    return order_by_for_day_num(1) unless Setting.show_day2

    "#{order_by_for_day_num(1)} or #{order_by_for_day_num(2)}"
  end
end
