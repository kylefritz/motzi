class Admin::PickupListsController < ApplicationController
  before_action :redirect_unless_user_is_admin!

  layout 'application'

  def show
    date = Date.parse(params[:date])
    pickup_days = PickupDay.unscoped
      .where("pickup_at::date = ?", date)
      .order(:pickup_at)

    if pickup_days.empty?
      head :not_found
      return
    end

    @date = date
    @pickup_days = pickup_days

    # Aggregate orders across all pickup days on this date
    rows_hash = {}
    pickup_days.each do |pickup_day|
      pickup_day.menu.orders.not_skip.includes(:user, order_items: :item).each do |order|
        order_items = order.order_items.select { |oi| oi.pickup_day_id == pickup_day.id }
        next if order_items.empty?
        rows_hash[order.user] ||= []
        rows_hash[order.user].concat(order_items)
      end
    end

    @rows = rows_hash.sort_by { |user, _| user.sort_key }
  end
end
