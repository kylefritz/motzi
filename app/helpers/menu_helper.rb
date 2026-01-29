module MenuHelper
  def menu_pickup_summary(menu)
    return nil if menu.pickup_days.blank?
    menu.pickup_days.order(:pickup_at).map do |pickup_day|
      "#{pickup_day.day_abbr} #{pickup_day.pickup_at.strftime('%-l:%M %p')}"
    end.join(" / ")
  end
end
