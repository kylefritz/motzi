# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#

unless Item.pay_it_forward
  Item.create!(
    id: Item::PAY_IT_FORWARD_ID,
    name: 'Pay it forward',
    description: 'Support someone else in need.',
  )
end

unless Rails.env.test?
  unless CreditBundle.any?
    CreditBundle.create!(description: "6-Month", credits: 25, price: 125)
    CreditBundle.create!(description: "3-Month", credits: 12, price: 72)
  end
end

unless Menu.any?
  menu = Menu.create!(week_id: Time.zone.now.week_id)
  menu.make_current!
end
