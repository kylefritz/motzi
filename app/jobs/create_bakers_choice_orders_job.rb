class CreateBakersChoiceOrdersJob < ApplicationJob

  def perform(*args)
    return unless (2..5).include?(Time.zone.now.hour) # 2a-5a
    return unless Time.zone.now.monday?

    menu = Menu.current

    already_ordered = Set[*menu.orders.pluck(:user_id)]
    
    User.for_weekly_email.map do |user|
      next if already_ordered.include?(user.id)
      next if user == User.maya
      next if user == User.russell

      Order.transaction do
        user.orders.create!(menu: menu).tap do |order|
          order.order_items.create!(item: Item.bakers_choice)
        end
      end
    end
  end
end
