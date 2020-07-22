def rand_bool
  [true, false].sample
end

namespace :fake_data do
  desc "create 100 fake users"
  task users: :environment do
    unless Rails.env.development?
      throw "only create fake data in dev"
    end

    (0..100).map do
      User.create(
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        password: Faker::Lorem.characters(number: 10),
        email: Faker::Internet.email,
      ).tap do |u|
        u.day1_pickup = rand_bool
        if rand_bool
          u.additional_email = Faker::Internet.email
        end
        u.save!
      end
    end

  end

  desc "create fake orders for the current menu"
  task orders: :environment do
    unless Rails.env.development?
      throw "only create fake data in dev"
    end

    menu = Menu.current
    items = menu.menu_items
    User.subscribers.each do |user|
      # 15% chance user forgets to order
      if rand() < 0.15
        next
      end

      # a small number of people have comments
      comments = rand() < 0.10 ? Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 1) : nil

      Order.transaction do
        Order.create!(user: user, menu: menu, comments: comments).tap do |order|

          # pick a random item
          order.order_items.create!(item: items.sample.item)
        end
      end
    end
  end

end
