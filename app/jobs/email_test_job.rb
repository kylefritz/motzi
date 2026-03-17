class EmailTestJob < ApplicationJob
  queue_as :default

  def perform
    user = User.kyle
    raise "User.kyle not found — seed the database first" unless user

    menu = Menu.current
    order = user.orders.includes(order_items: :item).last
    credit_item = user.credit_items.last

    # Weekly menu email
    MenuMailer.with(menu: menu, user: user).weekly_menu_email.deliver_now

    # Haven't ordered reminder
    ReminderMailer.with(menu: menu, user: user).havent_ordered_email.deliver_now

    # Order confirmation (if Kyle has an order)
    if order
      ConfirmationMailer.with(order: order).order_email.deliver_now
    end

    # Credit purchase confirmation (if Kyle has a credit item)
    if credit_item
      ConfirmationMailer.with(credit_item: credit_item).credit_email.deliver_now
    end

    # Day-of pickup reminder (if Kyle has an order with items)
    if order&.order_items&.any?
      ReminderMailer.with(
        menu: menu,
        user: user,
        order_items: order.order_items
      ).day_of_email.deliver_now
    end

    Rails.logger.info "EmailTestJob: Sent test emails to #{user.email}"
  end
end
