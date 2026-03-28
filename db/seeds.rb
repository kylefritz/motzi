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

User.reset_column_information
unless User.system
  User.create!(
    id: User::SYSTEM_ID,
    email: 'motzi-system@localhost',
    first_name: 'Motzi',
    last_name: 'System',
  )
end

# Review app: create admin user with a random password.
# Use "Forgot your password?" on the login page to set a new one via Devise.
if ENV['REVIEW_APP'].present? && !User.find_by(email: 'kyle.p.fritz@gmail.com')
  User.create!(
    email: 'kyle.p.fritz@gmail.com',
    first_name: 'Kyle',
    last_name: 'Fritz',
    is_admin: true,
    password: SecureRandom.hex(16),
  )
end
