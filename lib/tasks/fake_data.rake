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
        u.is_first_half = rand_bool
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
    addons, items = menu.menu_items.partition(&:is_add_on?)
    User.where(send_weekly_email: true).each do |user|
      # 15% change user forgets to order
      if rand() < 0.15
        next
      end

      # a small number of people have feedback or comments
      feedback = rand() < 0.05 ? Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 1) : nil
      comments = rand() < 0.10 ? Faker::Lorem.paragraph(sentence_count: 1, random_sentences_to_add: 1) : nil

      Order.transaction do
        Order.create!(user: user, menu: menu, feedback: feedback, comments: comments).tap do |order|

          # pick a random item
          order.order_items.create!(item: items.sample.item)

          # 10% chance of adding any add on
          addons.each do |add_on|
            if rand() < 0.10
              order.order_items.create!(item: add_on.item)
            end
          end
        end
      end
    end
  end

end
