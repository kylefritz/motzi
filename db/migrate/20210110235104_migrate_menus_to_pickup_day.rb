class MigrateMenusToPickupDay < ActiveRecord::Migration[6.0]
  def up
    def make_pickup_day(menu, is_day1)
      day = is_day1 ? "day1" : "day2"
      wday = Setting.send("pickup_#{day}_wday")
      
      pick_hour = wday == 6 ? 7.hours : 12.hours + 3.hours
      
      pickup_at = Time.zone.from_week_id(menu.week_id).beginning_of_day + wday.days + pick_hour
      
      order_deadline_at = menu.send("#{day}_deadline")
      
      PickupDay.create(menu_id: menu.id, pickup_at: pickup_at, order_deadline_at: order_deadline_at)
    end
    
    PaperTrail.enabled false
    bar = ProgressBar.new(Menu.count)
    Menu.find_each do |m|
      day1 = make_pickup_day(m, true)
      day2 = Setting.show_day2 ? make_pickup_day(m, false) : day1 # move any accidental order items to day1
      
      m.orders.each do |o|
        o.order_items.each do |oi|
          oi.update!(pickup_day_id: oi.day1_pickup ? day1.id : day2.id)
        end
      end
      
      bar.increment!
    end
  ensure
    PaperTrail.enabled true
  end
  
  def down
    PickupDay.delete_all
  end
end
