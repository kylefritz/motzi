module DeadlineHelper
  def ordering_deadline_text(menu)
    menu.pickup_days.map(&:deadline_text).join(" or\n")
  end
end
