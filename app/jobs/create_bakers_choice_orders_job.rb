class CreateBakersChoiceOrdersJob < ApplicationJob

  def perform(*args)
    return unless (2..5).include?(Time.zone.now.hour) # 2a-5a
    return unless Time.zone.now.monday?

    User.for_bakers_choice.map do |user|
      Order.transaction do
        user.orders.create!(menu: Menu.current).tap do |order|
          order.order_items.create!(item: Item.bakers_choice)
        end
      end
    end
  end
end
