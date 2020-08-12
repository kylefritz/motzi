module DeadlineHelper
  def day_to_order_by_text(menu)
    pickup_day1 = menu.day1_pickup_at.strftime("%A")
    pickup_day1_deadline = menu.day1_deadline.strftime("%A")


    pickup_day2 = menu.day2_pickup_at.strftime("%A")
    pickup_day2_deadline = menu.day2_deadline.strftime("%A")

    day1 = "#{pickup_day1_deadline} for #{pickup_day1} pickup"

    return day1 if Setting.single_pickup_day?

    "#{day1} or #{pickup_day2_deadline} for #{pickup_day2} pickup"
  end
end
