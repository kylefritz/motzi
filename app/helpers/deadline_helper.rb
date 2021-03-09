module DeadlineHelper
  def ordering_deadline_text(menu)
    menu.pickup_days.map(&:deadline_text).map{|t| "for #{t}"}.join(" or\n")
  end
end
