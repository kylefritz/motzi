class AddSaveDeadlineToMenus < ActiveRecord::Migration[6.0]
  def change
    Menu.find_each do |menu|
      if menu.week_id <= "20w13"
        day1 = :tuesday
        day2 = :thursday
      else
        day1 = Setting.pickup_day1.downcase.to_sym
        day2 = Setting.pickup_day2.downcase.to_sym
      end
      day1_deadline, day1_pickup_at = Menu.deadline_and_pickup(menu.week_id, Date::DAYS_INTO_WEEK[day1])
      day2_deadline, day2_pickup_at = Menu.deadline_and_pickup(menu.week_id, Date::DAYS_INTO_WEEK[day2])

      menu.update!(
        day1_deadline: day1_deadline,
        day1_pickup_at: day1_pickup_at,
        day2_deadline: day2_deadline,
        day2_pickup_at: day2_pickup_at,
      )
    end
  end
end
