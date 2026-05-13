module MarketingHelper
  def holiday_menu_link
    holiday = Menu.current_holiday
    return nil if holiday.nil?

    link_to(holiday.name, menu_path(holiday), class: "marketing-nav-holiday")
  end
end
