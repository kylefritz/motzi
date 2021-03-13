class ConvertMenuItemsToMenuItemPickupDays < ActiveRecord::Migration[6.0]
  def up
    bar = ProgressBar.new(MenuItem.count)
    MenuItem.find_each do |mi|
      day1, day2 = mi.menu.pickup_days

      if mi.day1?
        mi.menu_item_pickup_days.create!(
          pickup_day: day1,
          limit: mi.day1_limit
        )
      end
      if mi.day2? && day2.present?
        mi.menu_item_pickup_days.create!(
          pickup_day: day2,
          limit: mi.day2_limit,
        )
      end
      
      bar.increment!
    end
  end

  def down
  end
end
