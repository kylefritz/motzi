class Admin::PickupListsController < ApplicationController
  before_action :redirect_unless_user_is_admin!

  def show
    date = Date.parse(params[:date])
    pickup_day = PickupDay.unscoped
      .where("pickup_at::date = ?", date)
      .order(:pickup_at)
      .first

    if pickup_day
      redirect_to admin_pickup_day_path(pickup_day)
    else
      head :not_found
    end
  end
end
